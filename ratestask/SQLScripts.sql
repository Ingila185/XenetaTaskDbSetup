CREATE TABLE public.routes (
	route_code text NOT NULL,
	orig_code text NOT NULL,
	dest_code text NOT NULL,
	CONSTRAINT routes_pkey PRIMARY KEY (route_code)
);


-- public.routes foreign keys

ALTER TABLE public.routes ADD CONSTRAINT routes_dest_code_fkey FOREIGN KEY (dest_code) REFERENCES public.ports(code);
ALTER TABLE public.routes ADD CONSTRAINT routes_orig_code_fkey FOREIGN KEY (orig_code) REFERENCES public.ports(code);



CREATE TABLE public.ports (
	code text NOT NULL,
	"name" text NOT NULL,
	parent_slug text NOT NULL,
	CONSTRAINT ports_pkey PRIMARY KEY (code)
);


-- public.ports foreign keys

ALTER TABLE public.ports ADD CONSTRAINT ports_parent_slug_fkey FOREIGN KEY (parent_slug) REFERENCES public.regions(slug);

-- public.prices definition

-- Drop table

-- DROP TABLE public.prices;

CREATE TABLE public.prices (
	"day" date NOT NULL,
	price int4 NOT NULL,
	route_code text NULL
);


-- public.prices foreign keys

ALTER TABLE public.prices ADD CONSTRAINT routes_code_fkey FOREIGN KEY (route_code) REFERENCES public.routes(route_code);


-- public.regions definition

-- Drop table

-- DROP TABLE public.regions;

CREATE TABLE public.regions (
	slug text NOT NULL,
	"name" text NOT NULL,
	parent_slug text NULL,
	CONSTRAINT regions_pkey PRIMARY KEY (slug),
	CONSTRAINT regions_parent_slug_fkey FOREIGN KEY (parent_slug) REFERENCES public.regions(slug)
);



-- DROP FUNCTION public.get_average_prices_port_to_port(text, text, date, date);

CREATE OR REPLACE FUNCTION public.get_average_prices_port_to_port(p_orig_code text, p_dest_code text, p_date_from date, p_date_to date)
 RETURNS TABLE(price integer, day date)
 LANGUAGE sql
AS $function$
WITH grouped_data AS (
    SELECT day, avg(price) AS avg_price, count(*) AS price_count
    FROM public.prices where route_code in (select route_code from routes 
	where orig_code = p_orig_code and dest_code = p_dest_code)
	and day >= p_date_from and day <= p_date_to
    GROUP BY day order by day
)
SELECT avg_price, day
FROM grouped_data
WHERE price_count >= 3
UNION ALL
SELECT NULL, day
FROM generate_series(
    p_date_from,
    p_date_to,
    '1 day'::interval
) AS day
WHERE day NOT IN (SELECT day FROM grouped_data) order by day
;
$function$
;

-- DROP FUNCTION public.get_average_prices_port_to_region(text, text, date, date);

CREATE OR REPLACE FUNCTION public.get_average_prices_port_to_region(p_orig_code text, p_dest_code text, p_date_from date, p_date_to date)
 RETURNS TABLE(price integer, day date)
 LANGUAGE sql
AS $function$
WITH grouped_data AS (
    SELECT day, avg(price) AS avg_price, count(*) AS price_count
    FROM public.prices where route_code in (select route_code from public.get_valid_routes_port_to_region_slug(p_orig_code,p_dest_code ))
	and day >= p_date_from and day <= p_date_to
    GROUP BY day order by day
)
SELECT avg_price, day
FROM grouped_data
WHERE price_count >= 3
UNION ALL
SELECT NULL, day
FROM generate_series(
    p_date_from,
    p_date_to,
    '1 day'::interval
) AS day
WHERE day NOT IN (SELECT day FROM grouped_data) order by day
;
$function$
;


-- DROP FUNCTION public.get_valid_routes_port_to_region_slug(text, text);

CREATE OR REPLACE FUNCTION public.get_valid_routes_port_to_region_slug(p_orig_code text, p_dest_slug text)
 RETURNS TABLE(code text, name text, route_code text, orig_code text, dest_code text)
 LANGUAGE sql
AS $function$
SELECT * from public.get_ports_in_region_slug(p_dest_slug)
join routes  r on r.dest_code in (code) and r.orig_code = p_orig_code

$function$
;

-- DROP FUNCTION public.get_ports_in_region_slug(text);

CREATE OR REPLACE FUNCTION public.get_ports_in_region_slug(p_region_slug text)
 RETURNS TABLE(code text, name text)
 LANGUAGE sql
AS $function$
WITH RECURSIVE region_hierarchy AS (
    SELECT slug, parent_slug
    FROM public.regions
    UNION ALL
    SELECT r.slug, r.parent_slug
    FROM region_hierarchy rh
    JOIN public.regions r ON rh.slug = r.parent_slug
)
SELECT p.code, p.name
FROM public.ports p
JOIN region_hierarchy rh ON p.parent_slug = rh.slug
WHERE rh.slug = p_region_slug; -- Use the provided argument
$function$
;


-- DROP FUNCTION public.get_average_prices_region_to_port(text, text, date, date);

CREATE OR REPLACE FUNCTION public.get_average_prices_region_to_port(p_orig_code text, p_dest_code text, p_date_from date, p_date_to date)
 RETURNS TABLE(price integer, day date)
 LANGUAGE sql
AS $function$
WITH grouped_data AS (
    SELECT day, avg(price) AS avg_price, count(*) AS price_count
    FROM public.prices where route_code in (select route_code from public.get_valid_routes_region_slug_to_port_code(p_orig_code,p_dest_code ))
	and day >= p_date_from and day <= p_date_to
    GROUP BY day order by day
)
SELECT avg_price, day
FROM grouped_data
WHERE price_count >= 3
UNION ALL
SELECT NULL, day
FROM generate_series(
    p_date_from,
    p_date_to,
    '1 day'::interval
) AS day
WHERE day NOT IN (SELECT day FROM grouped_data) order by day
;
$function$
;


-- DROP FUNCTION public.get_valid_routes_region_slug_to_port_code(text, text);

CREATE OR REPLACE FUNCTION public.get_valid_routes_region_slug_to_port_code(p_orig_slug text, p_dest_code text)
 RETURNS TABLE(code text, name text, route_code text, orig_code text, dest_code text)
 LANGUAGE sql
AS $function$
SELECT * from public.get_ports_in_region_slug(p_orig_slug) --get all ports from the origin region
join routes  r on r.orig_code in (code) and r.dest_code = p_dest_code

$function$
;



-- DROP FUNCTION public.get_average_prices_region_to_region(text, text, date, date);

CREATE OR REPLACE FUNCTION public.get_average_prices_region_to_region(p_orig_code text, p_dest_code text, p_date_from date, p_date_to date)
 RETURNS TABLE(price integer, day date)
 LANGUAGE sql
AS $function$
WITH grouped_data AS (
    SELECT day, avg(price) AS avg_price, count(*) AS price_count
    FROM public.prices where route_code in (select route_code from public.get_valid_routes_region_to_region(p_orig_code,p_dest_code ))
	and day >= p_date_from and day <= p_date_to
    GROUP BY day order by day
)
SELECT avg_price, day
FROM grouped_data
WHERE price_count >= 3
UNION ALL
SELECT NULL, day
FROM generate_series(
    p_date_from,
    p_date_to,
    '1 day'::interval
) AS day
WHERE day NOT IN (SELECT day FROM grouped_data) order by day
;
$function$
;


-- DROP FUNCTION public.get_valid_routes_region_to_region(text, text);

CREATE OR REPLACE FUNCTION public.get_valid_routes_region_to_region(p_orig_slug text, p_dest_code text)
 RETURNS TABLE(code text)
 LANGUAGE sql
AS $function$
with orig_region_ports as (select code from public.get_ports_in_region_slug(p_orig_slug)),
	 dest_region_ports as (select code from public.get_ports_in_region_slug(p_dest_code))

select distinct(r.route_code) from routes r JOIN orig_region_ports op ON r.orig_code = op.code
JOIN dest_region_ports dp ON r.dest_code = dp.code;

--join routes  r on r.orig_code in (code) and r.dest_code in (p_dest_code)

$function$
;


-- public.route_id_seq definition

-- DROP SEQUENCE public.route_id_seq;


CREATE SEQUENCE route_id_seq START 1 INCREMENT 1;


--Insert all of prices data routes into routes table 

INSERT INTO public.routes (route_code, orig_code, dest_code)
SELECT nextval('route_id_seq'), orig_code, dest_code
FROM public.prices
GROUP BY orig_code, dest_code;


--Modify Prices add column of route_code

alter table public.prices  add route_code text 
ALTER TABLE public.prices ADD CONSTRAINT routes_code_fkey FOREIGN KEY (route_code) REFERENCES public.routes(route_code);


--Update Prices table set route_code to route_code Pk in Routes table.

UPDATE public.prices p
SET route_code = r.route_code
FROM public.routes r
WHERE p.orig_code = r.orig_code AND p.dest_code = r.dest_code;

--Drop unnecessary columns from Price

alter table prices drop column orig_code 
alter table prices drop column dest_code



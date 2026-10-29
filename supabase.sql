-- Figurerunning: gedeelde kaart met alle tekeningen
-- Plak dit hele bestand in Supabase: SQL Editor → New query → plakken → Run.
-- Je kunt het veilig nog een keer uitvoeren; bestaande tekeningen blijven staan.

create table if not exists public.drawings (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  segs        jsonb   not null,            -- [{"c":"#ff2d55","p":[[lat,lng],...]}, ...]
  km          numeric(8,2) not null default 0,
  lat         double precision not null,   -- midden van de tekening, voor de galerij
  lng         double precision not null,
  hidden      boolean not null default false,   -- zet op true om een tekening van de kaart te halen
  secret_hash text not null,               -- hash van het geheim dat alleen de maker heeft
  constraint segs_is_array check (jsonb_typeof(segs) = 'array'),
  constraint segs_size check (jsonb_array_length(segs) between 1 and 300 and length(segs::text) <= 400000)
);

create index if not exists drawings_created_idx on public.drawings (created_at desc);

-- Rechten: iedereen mag de zichtbare tekeningen lezen, niemand schrijft rechtstreeks in de tabel.
alter table public.drawings enable row level security;

drop policy if exists "lezen zichtbare tekeningen" on public.drawings;
create policy "lezen zichtbare tekeningen" on public.drawings
  for select to anon, authenticated using (not hidden);

revoke all on public.drawings from anon, authenticated;
grant select (id, created_at, segs, km, lat, lng) on public.drawings to anon, authenticated;

-- Tekening plaatsen. De app geeft een eigen geheim mee, zodat alleen de maker hem later kan weghalen.
create or replace function public.publish_drawing(p_segs jsonb, p_secret text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  seg jsonb; pt jsonb;
  prev_lat double precision; prev_lng double precision;
  la double precision; lo double precision;
  sum_lat double precision := 0; sum_lng double precision := 0;
  npts int := 0; meters double precision := 0;
  new_id uuid;
begin
  if p_secret is null or length(p_secret) < 16 or length(p_secret) > 200 then
    raise exception 'ongeldig geheim';
  end if;
  if p_segs is null or jsonb_typeof(p_segs) <> 'array' or jsonb_array_length(p_segs) not between 1 and 300
     or length(p_segs::text) > 400000 then
    raise exception 'ongeldige tekening';
  end if;

  -- Rem tegen overspoelen: maximaal 100 nieuwe tekeningen per 10 minuten voor de hele site.
  if (select count(*) from public.drawings where created_at > now() - interval '10 minutes') >= 100 then
    raise exception 'te druk, probeer het later opnieuw';
  end if;

  for seg in select * from jsonb_array_elements(p_segs) loop
    if jsonb_typeof(seg) <> 'object' or jsonb_typeof(seg->'p') <> 'array'
       or coalesce(seg->>'c', '') !~ '^#[0-9a-fA-F]{6}$' then
      raise exception 'ongeldig lijnstuk';
    end if;
    prev_lat := null;
    for pt in select * from jsonb_array_elements(seg->'p') loop
      if jsonb_typeof(pt) <> 'array' or jsonb_array_length(pt) <> 2
         or jsonb_typeof(pt->0) <> 'number' or jsonb_typeof(pt->1) <> 'number' then
        raise exception 'ongeldig punt';
      end if;
      la := (pt->>0)::double precision; lo := (pt->>1)::double precision;
      if la not between -85 and 85 or lo not between -180 and 180 then
        raise exception 'punt buiten de kaart';
      end if;
      npts := npts + 1;
      if npts > 30000 then raise exception 'te veel punten'; end if;
      sum_lat := sum_lat + la; sum_lng := sum_lng + lo;
      if prev_lat is not null then
        meters := meters + sqrt(
          power((lo - prev_lng) * 111320 * cos(radians((la + prev_lat) / 2)), 2) +
          power((la - prev_lat) * 110540, 2));
      end if;
      prev_lat := la; prev_lng := lo;
    end loop;
  end loop;

  if npts < 2 then raise exception 'te weinig punten'; end if;

  insert into public.drawings (segs, km, lat, lng, secret_hash)
  values (p_segs, round((meters / 1000)::numeric, 2), sum_lat / npts, sum_lng / npts,
          encode(sha256(convert_to(p_secret, 'UTF8')), 'hex'))
  returning id into new_id;
  return new_id;
end;
$$;

-- Eigen tekening van de kaart halen.
create or replace function public.unpublish_drawing(p_id uuid, p_secret text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare n int;
begin
  delete from public.drawings
   where id = p_id
     and secret_hash = encode(sha256(convert_to(coalesce(p_secret, ''), 'UTF8')), 'hex');
  get diagnostics n = row_count;
  return n > 0;
end;
$$;

revoke all on function public.publish_drawing(jsonb, text) from public;
revoke all on function public.unpublish_drawing(uuid, text) from public;
grant execute on function public.publish_drawing(jsonb, text) to anon, authenticated;
grant execute on function public.unpublish_drawing(uuid, text) to anon, authenticated;

-- Push do Firebase (FCM) para o celular Android do responsável: o SOS chega na
-- hora, sem esperar a conferência de 15 em 15 minutos.

-- Token do Android (FCM) não é hexadecimal como o da Apple.
create or replace function public.baru_familia_resp_push_token(p_chave text, p_token text, p_plataforma text, p_ambiente text default 'producao', p_idioma text default null)
returns boolean language plpgsql volatile security definer set search_path = public, extensions, pg_temp as $$
begin
  if p_chave is null or length(p_chave) <> 64 then return false; end if;
  if p_token is not null then
    if p_plataforma = 'android' then
      if p_token !~ '^[A-Za-z0-9:_-]+$' or length(p_token) not between 100 and 4096 then return false; end if;
    elsif p_token !~ '^[0-9a-fA-F]{32,200}$' then
      return false;
    end if;
  end if;
  update public.baru_familia_resp_aparelhos set
    push_token = p_token,
    plataforma = case when p_plataforma in ('ios', 'android') then p_plataforma end,
    push_ambiente = case when p_ambiente = 'sandbox' then 'sandbox' else 'producao' end,
    idioma = case when p_idioma in ('pt', 'en', 'es', 'zh') then p_idioma else idioma end,
    visto_em = now()
  where chave_hash = encode(digest(p_chave, 'sha256'), 'hex');
  return found;
end;
$$;

-- Evento que vira aviso → função de push, se algum responsável tem token (iPhone ou Android).
create or replace function public.baru_familia_avisa_responsavel() returns trigger
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
begin
  if not public.baru_familia_aviso_ligado(new.tipo, (select r.avisos from public.baru_familia_regras r where r.crianca_id = new.crianca_id)) then
    return new;
  end if;
  if not exists (select 1 from public.baru_familia_resp_aparelhos a
                   join public.baru_familia_membros m on m.user_id = a.user_id and m.familia_id = new.familia_id
                    and m.papel = 'responsavel' and m.saiu_em is null
                  where a.push_token is not null and a.plataforma in ('ios', 'android')) then
    return new;
  end if;
  perform net.http_post(
    url := 'https://slqpuppkapiewjqvedtj.supabase.co/functions/v1/familia-push',
    headers := jsonb_build_object('Content-Type', 'application/json'),
    body := jsonb_build_object('evento_id', new.id)
  );
  return new;
end;
$$;

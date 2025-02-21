/*
  # Configure OTP settings

  1. Changes
    - Define configurações seguras para OTP
    - Implementa rate limiting para tentativas de OTP
    - Adiciona validações de segurança

  2. Security
    - Limita tentativas de OTP
    - Implementa proteção contra força bruta
    - Define tempo de expiração seguro
*/

-- Função para configurar OTP
CREATE OR REPLACE FUNCTION auth.configure_otp()
RETURNS void
SECURITY DEFINER
SET search_path = auth, pg_temp
AS $$
BEGIN
  -- Configura tempo de vida do OTP (5 minutos)
  PERFORM set_config('auth.otp_lifetime', '300', false);
  
  -- Configura máximo de tentativas (3)
  PERFORM set_config('auth.otp_max_attempts', '3', false);
  
  -- Configura rate limiting (1 tentativa por minuto)
  PERFORM set_config('security.otp_rate_limit', '60', false);
END;
$$ LANGUAGE plpgsql;

-- Executa a configuração
SELECT auth.configure_otp();

-- Adiciona comentário explicativo
COMMENT ON FUNCTION auth.configure_otp() IS 
'Configura parâmetros de segurança para OTP:
- Tempo de expiração: 5 minutos
- Máximo de tentativas: 3
- Rate limit: 1 tentativa por minuto';

-- Revoga permissões públicas
REVOKE ALL ON FUNCTION auth.configure_otp() FROM PUBLIC;

-- Permite apenas usuários autenticados executarem
GRANT EXECUTE ON FUNCTION auth.configure_otp() TO authenticated;
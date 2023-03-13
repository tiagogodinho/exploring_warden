# Exemplos usando Warden para autenticação

## Exemplo 1 - Autênticação com sessão

Nesse exemplo temos um formulário de login que envia os dados para a rota `/sign_in`. Lá nós invocamos a autenticação com `env['warden'].authenticate!` que executa a estratégia `:password` que verifica se o usuário e senha estão na base de dados e monta a sessão e envia o cookie para o cliente.

Entrar na pasta do exemplo:

```
cd password_strategy/
```

Instalar as dependências:

```
bundle install
```

Executar o projeto:

```
rackup
```

## Exemplo 2 - Autênticação com token

No segundo exemplo a autenticação é feita na rota `/login` e passada para o warden através do comando `env['warden'].set_user(user, store: false)`. Com isso o **warden-jwt_auth** monta o token JWT e retorna para o cliente no header `Authorization`. Segue uns exemplos das requests usando `curl`.

```
curl --request POST \
  --url http://localhost:9292/sign_in \
  --header 'Content-Type: multipart/form-data' \
  --form email=developer@developer.com \
  --form password=12345678 \
  -v
```

```
curl --request GET \
  --url http://localhost:9292/user_info \
  --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwic2NwIjoiZGVmYXVsdCIsImF1ZCI6bnVsbCwiaWF0IjoxNjc4NzMyMTA4LCJleHAiOjE2Nzg3MzU3MDgsImp0aSI6ImY4OGU5YWEwLWQzMmUtNDgyMy04M2ZjLTVjYTViYmYxOThkNCJ9.FB_hfGm1C6O_4GFRuu0n8lqdVX2rE8647P7MMmh7oxQ'
```

Entrar na pasta do exemplo:

```
cd token_strategy/
```

Instalar as dependências:

```
bundle install
```

Executar o projeto:

```
rackup
```

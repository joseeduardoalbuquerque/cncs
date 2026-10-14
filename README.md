# CNCS — blacklists de IPs

Site para GitHub Pages com backend Supabase: login Google, aprovação de contas pelo administrador, várias listas por pessoa, partilha TXT, edição e eliminação. Administrador: **joseeduardoalbuquerque@gmail.com**.

O site fica em `https://joseeduardoalbuquerque.github.io/cncs/` após publicar. Cada TXT público tem um endereço `https://<projeto>.supabase.co/functions/v1/blacklist/<id>.txt`. É uma resposta de texto puro sem login; o endereço não termina no domínio GitHub porque precisa de verificar a partilha e a aprovação em cada pedido.

## Passo a passo

### 1. Colocar o código no GitHub

Envie os ficheiros deste projeto para `joseeduardoalbuquerque/cncs`, na branch `main`. Inclua `src`, `public`, `scripts`, `supabase`, `.github/workflows/pages.yml`, `package.json` e `package-lock.json`. Não envie `node_modules`, `dist`, `.env` ou dados locais. Num checkout ligado ao seu GitHub:

```sh
git add README.md .gitignore package.json package-lock.json src public scripts supabase .github test ip.js
git commit -m "Criar site de blacklists com Google e Supabase"
git push origin HEAD:main
```

Os comandos acima são instruções para publicação; não foram executados automaticamente. Se houver alterações remotas, sincronize e resolva conflitos antes de enviar; não use force push.

### 2. Criar o projeto Supabase

1. Em https://supabase.com/dashboard crie um projeto no plano Free, escolha a região e guarde a palavra-passe da base de dados num local seguro.
2. Abra **SQL Editor**, crie uma consulta, cole o conteúdo completo de `supabase/schema.sql` e execute. O script pode ser repetido.
3. Em **Connect** ou **Project Settings → API**, copie o endereço do projeto e a chave **publishable** (ou a chave legada **anon**). São configurações públicas do frontend. Nunca use `service_role`, `sb_secret_…`, palavra-passe da base de dados ou segredo Google no frontend/GitHub.
4. Em **Authentication → Providers**, desative login por email e outros fornecedores; configure Google no passo seguinte. A aplicação só cria perfis com identidade Google e email confirmado.

### 3. Configurar Google

1. Abra https://console.cloud.google.com/ e crie ou selecione um projeto.
2. Em **Google Auth Platform**, configure **Branding**, **Audience** (External) e os contactos solicitados. Para testes, adicione o seu email e os emails dos utilizadores de teste em **Audience → Test users**. Para qualquer pessoa poder entrar, publique a aplicação OAuth quando estiver pronta e cumpra os requisitos que o Google apresentar.
3. Em **Clients**, crie um cliente OAuth do tipo **Web application**.
4. Em **Authorized JavaScript origins**, adicione `https://joseeduardoalbuquerque.github.io`.
5. Em **Authorized redirect URIs**, adicione `https://<projeto>.supabase.co/auth/v1/callback` (substitua `<projeto>` pelo seu identificador Supabase).
6. Copie **Client ID** e **Client secret** para **Supabase → Authentication → Providers → Google**, ative Google e guarde. O segredo fica apenas no Supabase.
7. Em **Supabase → Authentication → URL Configuration**, defina **Site URL** e adicione aos **Redirect URLs** o endereço exato `https://joseeduardoalbuquerque.github.io/cncs/`, incluindo a barra final.

### 4. Publicar o endpoint TXT

A função está em `supabase/functions/blacklist/index.ts`. Utilize a CLI Supabase num computador com Node.js:

```sh
npx supabase login
npx supabase link --project-ref SEU_PROJECT_REF
npx supabase functions deploy blacklist --no-verify-jwt
```

Execute a partir da raiz do projeto. `SEU_PROJECT_REF` é o identificador do endereço Supabase. Faça a autenticação da CLI localmente; não coloque o token em ficheiros do site. O endpoint precisa de **verify JWT desativado** para leitores anónimos. A função não usa a chave service-role: usa a chave anon fornecida pelo Supabase e uma função SQL que só devolve listas públicas de contas aprovadas. Pode também publicar pelo editor de Edge Functions do dashboard, com o mesmo código e a verificação JWT desativada.

### 5. Publicar no GitHub Pages

1. Em **GitHub → cncs → Settings → Secrets and variables → Actions → Variables**, crie duas **Repository variables**:
   - `SUPABASE_URL`: `https://<projeto>.supabase.co`, sem barra final.
   - `SUPABASE_PUBLISHABLE_KEY`: chave publishable ou anon do passo 2.
2. Em **Settings → Pages → Build and deployment → Source**, escolha **GitHub Actions**. No plano gratuito, use um repositório público.
3. Em **Actions → Publicar site → Run workflow**, execute na branch `main`. Também é executado em cada push para `main`.
4. Aguarde a conclusão e abra `https://joseeduardoalbuquerque.github.io/cncs/`.

### 6. Verificar o serviço

1. Entre com `joseeduardoalbuquerque@gmail.com`: deverá ver **Utilizadores** e acesso automático.
2. Entre com outra conta Google: deve aparecer **A aguardar aprovação**, sem criação de listas.
3. Na sua conta de administrador, aprove essa pessoa em **Utilizadores**. A pessoa atualiza a página e passa a criar listas.
4. Crie uma lista, introduza `192.0.2.1` e `2001:db8::1`, e guarde. São endereços de exemplo.
5. A lista deve começar privada. Ative a partilha, guarde e abra o link TXT numa janela sem sessão: deve devolver os IPs, um por linha.
6. Desative a partilha: o mesmo link deve responder 404. Teste também apagar a lista e revogar a aprovação de uma conta com listas públicas.
7. Teste um IP inválido: o servidor deve recusar guardar. Duas contas aprovadas só devem ver as suas próprias listas.

## Desenvolvimento e limites

Node.js 24+. Instale com `npm ci`, execute `npm test` e `npm run test:db` (este último requer Docker e valida as permissões num PostgreSQL isolado). Estes testes também correm antes de publicar no GitHub Actions. Gere o site com:

```sh
SUPABASE_URL=https://SEU_PROJETO.supabase.co SUPABASE_PUBLISHABLE_KEY=SUA_CHAVE_PUBLICA npm run build
npm start
```

Adicione `http://localhost:3000/` aos Redirect URLs no Supabase para login local. A aplicação usa o SDK oficial Supabase, empacotado localmente, e OAuth PKCE. A base de dados aplica RLS; perfis não podem ser editados diretamente pelo utilizador. O administrador pode aprovar, recusar ou revogar acesso, mas não lê listas privadas alheias. Os IPs aceitam IPv4, IPv6 e prefixos CIDR. O tamanho máximo por lista é 1 MB. Não se fazem chamadas aos IPs inseridos.

Desativar partilha ou revogar acesso não apaga cópias previamente descarregadas. Ao reativar uma lista, o mesmo link volta a funcionar. Descarregar TXT guarda o conteúdo atual do editor, incluindo alterações ainda não guardadas. A conta recusada permanece registada e pode voltar a ser aprovada. Não há eliminação de conta nesta versão.

O plano gratuito tem quotas, incluindo funções, base de dados e autenticação, e projetos inativos podem ser pausados; consulte os limites atuais antes de abrir o serviço. Não há SLA gratuito nem promessa de disponibilidade contínua. Configure backups/exportações e acompanhe utilização se os links forem usados por ferramentas de produção.

Build e testes locais não substituem validação no seu projeto real. Google OAuth, publicação Pages e a função Supabase precisam da configuração da sua conta descrita acima.

# Painel CRM

Mini CRM + painel financeiro para freelancer/agência. Site estático (um único `index.html`),
sem build e sem dependências. Os dados ficam no `localStorage` do navegador.

## Rodar localmente
1. Abra a pasta no VS Code.
2. Instale a extensão **Live Server** (Ritwick Dey).
3. Clique com o botão direito em `index.html` → **Open with Live Server**.
   (Também funciona dando dois cliques em `index.html`.)

## Publicar: GitHub + Vercel
1. Instale o Git (git-scm.com) e crie conta no GitHub e na Vercel.
2. No terminal do VS Code (Ctrl + '), dentro da pasta do projeto:
   git init
   git add .
   git commit -m "Primeira versão do CRM"
   git branch -M main
3. No GitHub: New repository → nome `painel-crm` → Create (não marque README).
4. Copie os 2 comandos que o GitHub mostra e rode:
   git remote add origin https://github.com/SEU-USUARIO/painel-crm.git
   git push -u origin main
5. Na Vercel: Add New → Project → Continue with GitHub → escolha `painel-crm`.
6. Framework Preset: **Other**. Deixe Build Command e Output Directory em branco. Clique **Deploy**.
7. A cada `git add . && git commit -m "..." && git push`, a Vercel publica de novo sozinha.

## Importante
- Os dados do `localStorage` são separados por endereço: o que você cadastrar no Live Server
  não aparece no site da Vercel. Para levar dados, use Configurações → Exportar backup e
  depois Importar backup no outro endereço.
- Trocar de navegador ou limpar dados do navegador apaga os dados. Faça backups.
- Para banco real, veja `schema.sql`, `BACKEND_SETUP.md` e `.env.example`.

## Login e contas
- Usuário antigo (só neste navegador): TESTE1212 (a senha é a que você definiu).
- Qualquer pessoa pode clicar em "Criar conta". Nomes de usuário são únicos (sem diferenciar maiúsculas de minúsculas) e cada conta tem seus próprios dados e dashboard.
- **Sem configurar nada**, as contas ficam salvas no navegador daquele aparelho (não aparecem em outro computador/celular).

## Contas na nuvem (banco de dados real, Supabase)
1. Crie um projeto grátis em supabase.com.
2. Supabase → SQL Editor → New query → cole o conteúdo de `supabase-setup.sql` → Run.
3. Supabase → Authentication → Providers → Email → **desative "Confirm email"** → Save.
   (O app usa o nome de usuário como e-mail interno `usuario@painel-crm.app`.)
4. Supabase → Project Settings → API → copie **Project URL** e a chave **anon public**.
5. No `index.html`, procure `CRM_CONFIG` (perto do começo do `<script>`) e preencha:
   const CRM_CONFIG={SUPABASE_URL:'https://SEU-PROJETO.supabase.co',SUPABASE_ANON_KEY:'sua-anon-key'};
   (a anon key é pública por design; NUNCA use a service_role key aqui.)
6. `git add .` → `git commit -m "Ativa Supabase"` → `git push`. A Vercel republica sozinha.
7. Teste: crie uma conta no computador e entre com ela no celular.

Depois disso os dados de cada conta ficam no PostgreSQL e o backup em JSON continua funcionando.

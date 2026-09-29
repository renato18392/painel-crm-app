# Do localStorage ao Supabase — guia de migração

O protótipo entregue (`crm-dashboard.html`) usa `localStorage` para poder
rodar sozinho, sem servidor. `schema.sql` já contém toda a estrutura
Postgres/Supabase (tabelas, relacionamentos, RLS) descrita no seu pedido,
pronta para um projeto real em React/Next.js. Este guia mostra como plugar
o banco sem reescrever a aplicação.

## 1. Camada de armazenamento abstrata

Nunca chame `localStorage` diretamente dos componentes. Centralize tudo
numa interface única e troque a implementação por trás dela:

```ts
// services/storage/StorageService.ts
export interface StorageService {
  list<T>(table: string): Promise<T[]>;
  create<T>(table: string, data: Partial<T>): Promise<T>;
  update<T>(table: string, id: string, data: Partial<T>): Promise<T>;
  remove(table: string, id: string): Promise<void>;
}
```

```ts
// services/storage/LocalStorageService.ts
export class LocalStorageService implements StorageService {
  private read(table: string) {
    return JSON.parse(localStorage.getItem(table) || '[]');
  }
  private write(table: string, rows: any[]) {
    localStorage.setItem(table, JSON.stringify(rows));
  }
  async list(table: string) { return this.read(table); }
  async create(table: string, data: any) {
    const rows = this.read(table);
    const row = { id: crypto.randomUUID(), ...data };
    rows.push(row);
    this.write(table, rows);
    return row;
  }
  async update(table: string, id: string, data: any) {
    const rows = this.read(table).map((r: any) => r.id === id ? { ...r, ...data } : r);
    this.write(table, rows);
    return rows.find((r: any) => r.id === id);
  }
  async remove(table: string, id: string) {
    this.write(table, this.read(table).filter((r: any) => r.id !== id));
  }
}
```

```ts
// services/storage/SupabaseStorageService.ts
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

export class SupabaseStorageService implements StorageService {
  async list(table: string) {
    const { data, error } = await supabase.from(table).select('*');
    if (error) throw error;
    return data;
  }
  async create(table: string, data: any) {
    const { data: row, error } = await supabase.from(table).insert(data).select().single();
    if (error) throw error;
    return row;
  }
  async update(table: string, id: string, data: any) {
    const { data: row, error } = await supabase.from(table).update(data).eq('id', id).select().single();
    if (error) throw error;
    return row;
  }
  async remove(table: string, id: string) {
    const { error } = await supabase.from(table).delete().eq('id', id);
    if (error) throw error;
  }
}
```

```ts
// services/storage/index.ts
export const storage: StorageService = process.env.NEXT_PUBLIC_SUPABASE_URL
  ? new SupabaseStorageService()
  : new LocalStorageService();
```

Os componentes e hooks (ex.: `useContacts()`) sempre chamam `storage.list('contacts')`,
`storage.create('contacts', {...})` etc. — trocar a fonte de dados não exige
tocar em nenhuma tela.

## 2. Configurar o Supabase

1. Crie um projeto em supabase.com.
2. No SQL editor, rode o arquivo `schema.sql` (já inclui RLS e policies).
3. Ative o provedor de autenticação que preferir (e-mail/senha, Google, etc.)
   em *Authentication → Providers*.
4. Copie a URL e a `anon key` do projeto (*Settings → API*).

## 3. Variáveis de ambiente

Crie um `.env.local` (nunca commitado) a partir do `.env.example`:

```
NEXT_PUBLIC_SUPABASE_URL=https://SEU-PROJETO.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sua-anon-key-publica
```

A `anon key` é segura no frontend porque o RLS do banco garante que cada
usuário só lê/escreve suas próprias linhas — nunca use a `service_role key`
no navegador.

## 4. Tempo real (opcional)

Para refletir mudanças sem recarregar a página:

```ts
supabase
  .channel('contacts-changes')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'contacts' }, payload => {
    // atualizar estado local com payload.new / payload.old
  })
  .subscribe();
```

## 5. Caminho de expansão

Como tudo passa pela mesma interface `StorageService` e o banco já tem
`user_id` em cada tabela com RLS, dá para adicionar depois, sem reescrever
o app: múltiplos usuários, equipes/permissões (tabela `teams` +
`team_members`), integrações (webhooks para WhatsApp/e-mail) e uma API
própria (rotas Next.js que chamam o mesmo `SupabaseStorageService` no
servidor, usando a service_role key).

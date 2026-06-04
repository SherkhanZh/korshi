// Minimal ambient types for the experimental built-in `node:sqlite` module,
// so the project type-checks regardless of @types/node version.
declare module 'node:sqlite' {
  export interface StatementSync {
    run(...params: unknown[]): { changes: number; lastInsertRowid: number | bigint };
    get(...params: unknown[]): any;
    all(...params: unknown[]): any[];
  }
  export class DatabaseSync {
    constructor(path: string, options?: { open?: boolean });
    exec(sql: string): void;
    prepare(sql: string): StatementSync;
    close(): void;
  }
}

declare module 'sql.js' {
  export interface SqlJsConfig {
    locateFile?: (file: string) => string;
  }

  export interface SqlJsDatabase {
    run(sql: string, params?: any[]): void;
    exec(sql: string): Array<{ columns: string[]; values: any[] }>;
    prepare(sql: string): any;
    export(): Uint8Array;
    close(): void;
  }

  function initSqlJs(config?: SqlJsConfig): Promise<any>;
  export default initSqlJs;
  export { initSqlJs, SqlJsDatabase as Database };
}

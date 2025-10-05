export const port = 40001

export const logFilters = {
  ERROR: 'Error',
  WARN: 'Warning',
  INFO: 'Info',
  DEBUG: 'Debug',
  TRACE: 'Trace',
}

export type LogFilters = keyof typeof logFilters

export const configDefaults = {
  cookie_file: '/mnt/bitcoind/testnet4/.cookie' as const,
  daemon_rpc_addr: 'bitcoind-testnet.startos:48332' as const,
  daemon_p2p_addr: 'bitcoind-testnet.startos:8333' as const,
  network: 'testnet4' as const,
  electrum_rpc_addr: `0.0.0.0:${port}` as const,
  log_filters: 'INFO' as LogFilters,
  index_batch_size: 10,
  index_lookup_limit: 0,
}

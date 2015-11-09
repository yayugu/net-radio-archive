module OndemandRetry
  STATE = {
    waiting: 'waiting',
    downloading: 'downloading',
    done: 'done',
    failed: 'failed',
    not_downloadable: 'not_downloadable',
    outdated: 'outdated',
  }
  RETRY_LIMIT = 3
end

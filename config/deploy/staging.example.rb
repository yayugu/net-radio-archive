# HOMEディレクトリ以下のrbenvを使う場合のPATH指定
#set :default_env, {
# path: '$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH'
#}

set :deploy_to, '/deploy/to/path'

server 'example.com', user: 'deploy', roles: %w{app db web}, my_property: :my_value
# or
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }

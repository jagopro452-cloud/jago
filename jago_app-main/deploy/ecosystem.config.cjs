module.exports = {
  apps: [
    {
      name: "jago",
      script: "./dist/index.js",
      cwd: "/var/www/jago",
      instances: 1,
      exec_mode: "fork",
      node_args: "",
      env_file: "/var/www/jago/.env",
      env: {
        NODE_ENV: "production",
        PORT: "5000",
      },
      watch: false,
      max_memory_restart: "512M",
      error_file: "/var/log/jago/error.log",
      out_file: "/var/log/jago/out.log",
      log_date_format: "YYYY-MM-DD HH:mm:ss",
      restart_delay: 3000,
      max_restarts: 10,
    },
  ],
};

# hysteria_oneclick_script

This script can simplify the config process of Hysteria.
此脚本可以简化 Hysteria 的配置过程。

# QUICK USAGE / 快速使用

Use this command to install Hysteria.
使用以下命令安装 Hysteria。

```bash
sudo bash <(curl -Ls https://raw.githubusercontent.com/locherli/hysteria_oneclick_script/master/hysteria_install.sh)
```

Use this command to get the basic info and URL of your proxy.
使用以下命令获取代理的基本信息和 URL。

```bash
bash <(curl -Ls https://raw.githubusercontent.com/locherli/hysteria_oneclick_script/master/hysteria_info.sh)
```

# FIELD CONFIGURATION / 配置字段说明

When the script runs, it will prompt you for the following fields. Please fill them in carefully according to your server environment.
脚本执行时，会依次询问以下字段，请根据你的服务器环境认真填写。

## 1) Certificate type / 证书类型

Prompt:
- `Choose certificate type (acme or self-signed, default: self-signed):`
- 证书类型选择（`acme` 或 `self-signed`，默认：`self-signed`）

Meaning:
- `self-signed`: generate a local certificate and use it directly. This is easier to configure and suitable for quick testing or private use.
- `acme`: use Let's Encrypt / ACME to automatically issue a certificate. This is recommended for public services with a real domain.

Notes:
- If you choose `acme`, the domain must resolve to the current server IP.
- If you choose `self-signed`, you need to provide a CN value for the certificate.

## 2) Authentication password / 认证密码

Prompt:
- `Enter authentication password (default: 123456):`
- 输入认证密码（默认：`123456`）

Meaning:
- This value is used for `auth.password` in the Hysteria config.
- Clients need this password to connect to the server.

Recommended:
- Use a strong password that is not easy to guess.

## 3) Masquerade URL / 伪装网址

Prompt:
- `Enter masquerade URL (default: https://cn.bing.com/):`
- 输入伪装 URL（默认：`https://cn.bing.com/`）

Meaning:
- This value is written to:
  - `masquerade.proxy.url`
- It is the URL used to hide the real traffic pattern and make the proxy look like normal web traffic.

Notes:
- The default value is a common website and is usually acceptable for testing.
- For production use, it is better to use a normal public HTTPS site or a site that is accessible from your environment.

## 4) Listen port / 监听端口

Prompt:
- `Enter listen port (default: 443):`
- 输入监听端口（默认：`443`）

Meaning:
- This sets the server's listening port.
- It is written as:
  - `listen: :443`

Notes:
- Common choices are `443` (standard HTTPS port) or other service ports.
- Make sure the firewall and cloud security group allow the chosen port.

## 5) ACME mode additional fields / ACME 模式额外字段

If you choose `acme`, the script will ask for:

- `Enter domain (must be resolved to this server's IP):`
- `Enter email for ACME:`

Meaning:
- `domain`: the domain name used for the certificate, such as `example.com`
- `email`: the email address used to register the ACME account

Notes:
- The domain must already resolve to the public IP of this server.
- Port 80 must be reachable for ACME HTTP challenge verification.

## 6) Self-signed mode additional field / 自签名模式额外字段

If you choose `self-signed`, the script will ask for:

- `Enter CN for self-signed cert (default: bing.com):`
- 输入自签名证书的 CN（默认：`bing.com`）

Meaning:
- `CN` is the certificate subject name, usually a domain name or a short descriptive name.
- This value is used to generate the certificate with OpenSSL.

Example:
- `bing.com`
- `myserver.local`

# GENERATED CONFIG FILE / 生成的配置文件

After the script finishes, the main configuration file is generated at:
脚本执行完成后，主要配置文件会生成在：

```bash
/etc/hysteria/config.yaml
```

The script will generate entries similar to this:
脚本将生成类似下面的配置：

```yaml
listen: :443

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: 123456

resolver:
  type: udp
  tcp:
    addr: 8.8.8.8:53
    timeout: 4s
  udp:
    addr: 8.8.4.4:53
    timeout: 4s
  tls:
    addr: 1.1.1.1:853
    timeout: 10s
    sni: cloudflare-dns.com
    insecure: false
  https:
    addr: 1.1.1.1:443
    timeout: 10s
    sni: cloudflare-dns.com
    insecure: false

masquerade:
  type: proxy
  proxy:
    url: https://cn.bing.com/
    rewriteHost: true
```

# EXAMPLE / 示例

Example input during script execution:
脚本执行过程中的示例输入：

```bash
Choose certificate type (acme or self-signed, default: self-signed): self-signed
Enter authentication password (default: 123456): myStrongPassword
Enter masquerade URL (default: https://cn.bing.com/): https://example.com/
Enter listen port (default: 443): 443
Enter CN for self-signed cert (default: bing.com): example.com
```

This will create a server that listens on port 443, uses `myStrongPassword` for authentication, and uses `https://example.com/` as the masquerade URL.
这将创建一个监听 443 端口、使用 `myStrongPassword` 作为认证密码，并使用 `https://example.com/` 作为伪装 URL 的服务器。

# Notes / 说明

- Run the script as root.
- If you change the config later, restart the service with:

```bash
sudo systemctl restart hysteria-server.service
```

- To view detailed status, use:

```bash
sudo systemctl status hysteria-server.service
```

- To get the proxy URL and basic config information, run:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/locherli/hysteria_oneclick_script/master/hysteria_info.sh)
```

# hysteria_oneclick_script

这个脚本可以简化 Hysteria 的配置过程。

语言: [English](README.md) | [中文](README.zh-CN.md)

## 快速使用

使用下面的命令安装 Hysteria：

```bash
sudo bash <(curl -Ls https://raw.githubusercontent.com/locherli/hysteria_oneclick_script/master/hysteria_install.sh)
```

使用下面的命令获取代理的基本信息和 URL：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/locherli/hysteria_oneclick_script/master/hysteria_info.sh)
```

## 配置字段说明

脚本运行时，会依次询问以下字段。请根据你的服务器环境认真填写。

### 1) 证书类型

提示：
- `Choose certificate type (acme or self-signed, default: self-signed):`

含义：
- `self-signed`：生成本地证书并直接使用，适合快速测试或私人环境，配置更简单。
- `acme`：使用 Let's Encrypt / ACME 自动签发证书，适合有真实域名的公网服务。

说明：
- 如果选择 `acme`，域名必须解析到当前服务器 IP。
- 如果选择 `self-signed`，需要提供一个 CN 值。

### 2) 认证密码

提示：
- `Enter authentication password (default: 123456):`

含义：
- 该值会写入 Hysteria 配置中的 `auth.password`。
- 客户端连接服务器时需要使用这个密码。

建议：
- 使用复杂且不容易猜到的密码。

### 3) 伪装 URL

提示：
- `Enter masquerade URL (default: https://cn.bing.com/):`

含义：
- 该值会写入：
  - `masquerade.proxy.url`
- 它用于伪装流量，让代理看起来更像正常的 HTTPS 访问。

说明：
- 默认值是常见网站，适合测试。
- 生产环境建议使用正常可访问的 HTTPS 站点。

### 4) 监听端口

提示：
- `Enter listen port (default: 443):`

含义：
- 用于设置服务监听端口。
- 会生成：
  - `listen: :443`

说明：
- 常见选择是 `443`（标准 HTTPS 端口）或其他可用端口。
- 请确保防火墙或云安全组允许该端口访问。

### 5) ACME 模式额外字段

如果选择 `acme`，脚本会继续询问：

- `Enter domain (must be resolved to this server's IP):`
- `Enter email for ACME:`

含义：
- `domain`：用于申请证书的域名，例如 `example.com`
- `email`：用于注册 ACME 账号的邮箱

说明：
- 域名必须已解析到当前服务器的公网 IP。
- ACME HTTP 挑战需要端口 80 可达。

### 6) 自签名模式额外字段

如果选择 `self-signed`，脚本会询问：

- `Enter CN for self-signed cert (default: bing.com):`

含义：
- `CN` 是证书主题名，通常是域名或简洁名称。
- 该字段用来生成 OpenSSL 自签名证书。

示例：
- `bing.com`
- `myserver.local`

## 生成的配置文件

脚本执行完成后，主配置文件会生成在：

```bash
/etc/hysteria/config.yaml
```

脚本会生成类似下面的配置：

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

## 示例

脚本执行过程中的示例输入：

```bash
Choose certificate type (acme or self-signed, default: self-signed): self-signed
Enter authentication password (default: 123456): myStrongPassword
Enter masquerade URL (default: https://cn.bing.com/): https://example.com/
Enter listen port (default: 443): 443
Enter CN for self-signed cert (default: bing.com): example.com
```

这将创建一个监听 443 端口、使用 `myStrongPassword` 作为认证密码，并使用 `https://example.com/` 作为伪装 URL 的服务器。

## 说明

- 请以 root 用户运行脚本。
- 如果后续修改配置，需要重启服务：

```bash
sudo systemctl restart hysteria-server.service
```

- 查看详细状态：

```bash
sudo systemctl status hysteria-server.service
```

- 获取代理 URL 和基础配置信息：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/locherli/hysteria_oneclick_script/master/hysteria_info.sh)
```

# 华为云代金券一键领取工具 (Huawei Cloud Voucher Claim)

<p align="center">
  <a href="https://github.com/billzai/huaweicloud-voucher-claim/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT">
  </a>
  <a href="https://www.gnu.org/software/bash/">
    <img src="https://img.shields.io/badge/Language-Bash%204.0+-4EAA25.svg?logo=gnu-bash&logoColor=white" alt="Bash">
  </a>
  <img src="https://img.shields.io/badge/Platform-CloudShell%20%7C%20Linux%20%7C%20macOS%20%7C%20WSL-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Dependency-curl%20only-02569B.svg?logo=curl&logoColor=white" alt="Dependency: curl">
  <a href="https://github.com/billzai/huaweicloud-voucher-claim/pulls">
    <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome">
  </a>
</p>

一键安全领取**华为开发者大赛 · 小红书 Skill 创新赛** 200 元赛事代金券 + 10 元日常激励券的自动化轻量工具。

针对华为官方 DevKit VS Code 插件内嵌 Webview 频繁出现的白屏、加载卡死、Node.js 运行时依赖报错等问题，本脚本直接与底层接口通信，**无需安装庞大的 IDE 扩展与 Node 环境，仅依赖 `bash` 与 `curl`，全平台 1 秒秒级到账**。

---

## 目录

- [特性优势](#特性优势)
- [前置条件](#前置条件)
- [快速上手](#快速上手)
  - [方式一：下载运行（推荐）](#方式一下载运行推荐)
  - [方式二：一键脚本执行](#方式二一键脚本执行)
  - [命令行选项说明](#命令行选项说明)
- [凭证输入方式](#凭证输入方式)
- [1.5 年低成本服务器购买攻略](#15-年低成本服务器购买攻略)
- [常见问题与排查 (FAQ)](#常见问题与排查-faq)
- [安全规约与最佳实践](#安全规约与最佳实践)
- [合规与免责声明 (Disclaimer)](#合规与免责声明-disclaimer)
- [开源协议](#开源协议)

---

## 特性优势

- 🚀 **极简轻量**：纯 Shell 编写，零第三方轮子，依赖仅限系统自带的 `bash` + `curl`。
- 🛡️ **安全防泄露**：凭证通过标准输入（stdin）管道传输给 `curl -K -`，进程列表（`ps aux` / `htop` / `/proc`）绝不暴露明文 AK/SK。
- 🧩 **全格式容错**：智能兼容控制台下载的 `credentials.csv`（单行/表头格式、两列/三列、UTF-8 BOM、Windows CRLF 换行、空行与引号干扰），彻底杜绝 `bad array subscript` 报错。
- ⚡ **绕过白屏缺陷**：摆脱 VS Code 插件内嵌网页加载缓慢、跨域报错和系统环境兼容性问题。
- 🌐 **代理兼容**：原生支持 `--noproxy` 选项，一键绕过本机梯子或局域网代理的干扰。

---

## 前置条件

在运行本脚本领券之前，请确保完成以下前置准备：

1. **华为云主账号**：必须使用**主账号**登录（IAM 子账号无权领取赛事代金券）。
2. **实名认证**：主账号已完成个人或企业实名认证。
3. **大赛报名与组队**：
   - 前往**华为开发者大赛 · 小红书 Skill 创新赛**官方赛事页面完成报名；
   - 在赛事页组建参赛队伍或加入现有团队（**未组队将提示无资格**）。
4. **获取访问密钥 (AK/SK)**：
   - 登录 [华为云控制台](https://console.huaweicloud.com/)；
   - 点击右上角头像 → 选择 **我的凭证** → 左侧进入 **访问密钥**；
   - 点击 **新增访问密钥**，下载保存为 `credentials.csv`。

---

## 快速上手

### 方式一：下载运行（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/billzai/huaweicloud-voucher-claim.git
cd huaweicloud-voucher-claim

# 2. 赋予执行权限
chmod +x claim.sh

# 3. 运行领券（传入下载的凭证文件）
./claim.sh credentials.csv
```

### 方式二：一键脚本执行

如在远程 Linux 服务器、CloudShell 或容器环境中，可直接一键拉取执行：

```bash
curl -fsSL https://raw.githubusercontent.com/billzai/huaweicloud-voucher-claim/main/claim.sh -o claim.sh
chmod +x claim.sh
./claim.sh
```

### 命令行选项说明

```bash
用法：
  ./claim.sh [选项] [credentials.csv]

选项：
  --only competition   只领 200 元赛事代金券
  --only incentive     只领 10 元激励代金券
  --status             只查询激励券状态
  --noproxy            强制直连（忽略系统 http/https 代理，解决代理冲突）
  -h, --help           显示帮助信息并退出
```

#### 常见用法示例

- **全量领取（默认推荐）**：
  ```bash
  ./claim.sh credentials.csv
  ```
- **仅领取 200 元赛事券**：
  ```bash
  ./claim.sh --only competition credentials.csv
  ```
- **开启了代理导致网络报错时（强制直连）**：
  ```bash
  ./claim.sh --noproxy credentials.csv
  ```
- **仅查看激励券领取状态**：
  ```bash
  ./claim.sh --status credentials.csv
  ```

---

## 凭证输入方式

脚本支持三种凭证提供方式，优先级如下：

1. **凭证文件传参（推荐，最省心）**：
   ```bash
   ./claim.sh credentials.csv
   ```
   自动解析华为云控制台导出的 CSV，兼容 2 列 / 3 列及各种格式。

2. **交互式安全输入（最安全，不落盘）**：
   ```bash
   ./claim.sh
   ```
   终端会提示输入 AK，随后输入 SK 时自动开启静默不回显模式，屏幕不留痕迹。

3. **环境变量传入（适合 CI/CD 或自动化运维）**：
   ```bash
   HW_ACCESS_KEY="你的AK" HW_SECRET_KEY="你的SK" ./claim.sh
   ```

---

## 1.5 年低成本服务器购买攻略

领取到 200 元大赛代金券后，如何最大化利用它的价值？推荐以下**「36元首购 + 200元券续费 6 个月」**玩法，轻松拿下 18 个月（1.5 年）轻量云服务器：

### 核心规则与避坑指南

> ⚠️ **关键认知：特价活动机型不能用券抵扣首付！**
> 华为云新客特价机（如 36 元/年、38 元/年的云耀云服务器 HECS）属于平台补贴特惠一口价，规则上**严禁使用代金券抵扣首购金额**。强行在下单时找代金券是无法抵扣的。

### 正确低成本撸机姿势

1. **第一步：现金 36 元完成特惠首购**
   - 前往华为云特惠专区（或新客特惠活动页）；
   - 选购 1 年期的特价云服务器（如云耀云服务器 HECS 2核2G / 1核2G 等，活动价格通常在 36~38 元左右）；
   - 下单并以现金/微信/支付宝支付 36 元，直接获得 **12 个月（1 年）** 时长。
2. **第二步：控制台发起续费 6 个月**
   - 机器开通完成后，进入控制台服务器列表，找到刚购买的实例；
   - 点击操作栏的 **更多 → 续费**；
   - 续费时长选择 **6 个月**；
   - 6 个月的基础续费金额通常在 180 ~ 200 元之间。
3. **第三步：使用 200 元赛事券抵扣结算**
   - 进入续费支付页面，在优惠折扣选项中勾选 **「使用代金券」**；
   - 选择刚领到的 **200 元华为开发者大赛赛事代金券**；
   - 代金券全额抵扣续费订单，实付金额变为 **0 元**，确认支付完成续费！
4. **最终成果**：
   - 实际总花费：**36 元人民币**；
   - 实际获得服务时长：**12 个月（首购） + 6 个月（续费） = 18 个月（1.5 年）**！

---

## 常见问题与排查 (FAQ)

### Q1: 为什么官方 VS Code 插件领券页面总是白屏或打不开？
**答**：华为官方 DevKit 插件在 VS Code 内依赖 Webview 渲染，常因系统内置浏览器内核版本较低、CSP 跨域策略拦截、VS Code 代理配置冲突或 Node.js 运行时环境异常导致渲染失败。本脚本直接向接口发送标准 HTTPS 请求，绕过所有前端渲染层，彻底解决白屏。

### Q2: 提示“网络请求失败”或连接超时怎么办？
**答**：若本地终端开启了系统代理工具（Clash、v2ray 等），可能劫持了向华为云 API 的 HTTPS 通信。请附加 `--noproxy` 参数强制直连：
```bash
./claim.sh --noproxy credentials.csv
```

### Q3: 提示 `HDKIT_CRED_INVALID` 是什么原因？
**答**：代表华为云鉴权失败，请检查：
1. 是否使用了 IAM 子账号？（必须使用华为云主账号生成的凭证）；
2. 复制的 AK/SK 是否完整，有无前后多余空格；
3. 该密钥是否已在控制台被禁用或删除。

### Q4: 提示“没有资格 / 请先报名组建团队”？
**答**：200 元赛事券是专属大赛权益，请务必先前往华为开发者大赛 · 小红书 Skill 创新赛页面：
1. 点击“立即报名”；
2. 必须点击“创建团队”或“加入团队”（即使是单人参赛也需要创建一个一人团队）。

### Q5: 提示“本月额度已用完”怎么办？
**答**：赛事主办方每月对全平台代金券发放设有总额度预算。若当月预算耗尽，可于次月 1 日 0 点重新运行脚本领取。

---

## 安全规约与最佳实践

- 🔐 **严禁会话上传密钥**：在使用 AI 助手或向他人求助时，**严禁将包含 AK/SK 的文本或 CSV 直接发送到聊天框中**。
- 🧹 **用完即删**：本脚本只在领券瞬间需要调用接口，领券成功后：
  1. 请立即登录 [华为云访问密钥控制台](https://console.huaweicloud.com/)；
  2. 找到本次使用的访问密钥，点击 **删除** 或 **禁用**；
  3. 删除本地留存的 `credentials.csv`，养成最小化安全凭证生命周期的良好习惯。

---

## 合规与免责声明 (Disclaimer)

1. **个人学习与研究**：本项目仅供个人开发者、参赛选手进行技术学习、API 接口研究与自动化参赛测试使用。
2. **严禁黑产与批量滥用**：严禁将本项目用于任何多账号批量套利、黑产薅羊毛、网络攻击、非法倒卖云资源或违反华为云《用户服务协议》之行为。
3. **责任自负**：用户对其提供的访问密钥安全性、网络环境合规性以及使用本脚本所产生的一切后果承担全部责任。因滥用、违规操作导致账号被封禁、资产冻结或追究法律责任的，本项目作者不承担任何连带责任。
4. **商标声明**：本项目涉及的“华为云”、“Huawei Cloud”商标及版权归华为技术有限公司所有，本项目与华为技术有限公司官方无任何雇佣、代言或商业关联。

---

## 开源协议

本项目基于 [MIT License](LICENSE) 协议开源。
```
Copyright (c) 2026 billzai
```

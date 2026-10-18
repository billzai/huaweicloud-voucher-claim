#!/usr/bin/env bash
# ==============================================================================
# 华为云代金券一键领取脚本 (huaweicloud-voucher-claim)
# 支持：华为开发者大赛·小红书 Skill 创新赛 200 元赛事券 + 10 元激励券
# 仓库：https://github.com/billzai/huaweicloud-voucher-claim
# ==============================================================================
set -euo pipefail
unset HISTFILE 2>/dev/null || true

BASE="${HDKITSERVICE_ENDPOINT:-https://devkit.huaweicloud.com/rest/developer/server/hdkitservice/}"
CLIENT_VERSION="${HDKIT_CLIENT_VERSION:-1.1.8}"

ONLY=""
STATUS_ONLY=0
USE_NOPROXY=0
CSV=""

usage() {
  cat << 'HELP'
华为云代金券一键领取工具：华为开发者大赛·小红书 Skill 创新赛赛事券 + 激励券

用法：
  ./claim.sh [选项] [credentials.csv]

选项：
  --only competition   只领 200 元赛事代金券
  --only incentive     只领 10 元激励代金券
  --status             只查询激励券状态
  --noproxy            强制直连（忽略系统 http/https 代理，解决代理冲突）
  -h, --help           显示本帮助信息并退出

密钥提供方式（三选一，安全优先级：凭证文件 > 交互输入 > 环境变量）：
  1) 凭证文件：./claim.sh credentials.csv
  2) 交互输入：./claim.sh （终端交互输入，SK 密码不回显）
  3) 环境变量：HW_ACCESS_KEY=xxx HW_SECRET_KEY=yyy ./claim.sh

项目主页：https://github.com/billzai/huaweicloud-voucher-claim
HELP
  exit 0
}

# 严格解析命令行参数
while [ $# -gt 0 ]; do
  case "$1" in
    --only)
      if [ $# -lt 2 ] || [[ "$2" =~ ^-- ]]; then
        echo "❌ 错误：--only 缺少必要参数，可选值为 competition 或 incentive" >&2
        exit 1
      fi
      if [ "$2" != "competition" ] && [ "$2" != "incentive" ]; then
        echo "❌ 错误：--only 参数无效 [$2]，必须为 competition 或 incentive" >&2
        exit 1
      fi
      ONLY="$2"
      shift 2
      ;;
    --only=*)
      val="${1#*=}"
      if [ "$val" != "competition" ] && [ "$val" != "incentive" ]; then
        echo "❌ 错误：--only 参数无效 [$val]，必须为 competition 或 incentive" >&2
        exit 1
      fi
      ONLY="$val"
      shift
      ;;
    --status)
      STATUS_ONLY=1
      shift
      ;;
    --noproxy)
      USE_NOPROXY=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    -*)
      echo "❌ 错误：未知选项 $1（使用 -h 或 --help 查看支持的参数）" >&2
      exit 1
      ;;
    *)
      if [ -n "$CSV" ]; then
        echo "❌ 错误：检测到多个凭证文件参数 [$CSV] 与 [$1]，请检查文件名是否有空格且未加引号" >&2
        exit 1
      fi
      CSV="$1"
      shift
      ;;
  esac
done

# 依赖检查：仅需 bash 与 curl
command -v curl >/dev/null 2>&1 || {
  echo "❌ 缺少依赖：需要 curl，请先安装 curl (如 apt install curl 或 yum install curl)" >&2
  exit 1
}

# 解析凭证 CSV
if [ -n "$CSV" ]; then
  if [ ! -f "$CSV" ]; then
    echo "❌ 找不到凭证文件：$CSV" >&2
    exit 1
  fi

  # 兼容 Windows CRLF、UTF-8 BOM、去除引号并过滤空行
  clean_data=$(LC_ALL=C sed -e '1s/^\xEF\xBB\xBF//' "$CSV" | tr -d '\r"' | grep -v '^[[:space:]]*$' || true)

  if [ -z "$clean_data" ]; then
    echo "❌ 凭证文件格式错误：文件内容为空或仅包含空白行" >&2
    exit 1
  fi

  # 智能判断第 1 行是否为表头
  first_line=$(echo "$clean_data" | sed -n '1p')
  if echo "$first_line" | grep -qiE "Access Key Id|访问密钥|Secret Access Key"; then
    target_line=$(echo "$clean_data" | sed -n '2p')
  else
    target_line="$first_line"
  fi

  if [ -z "$target_line" ]; then
    echo "❌ 凭证文件格式错误：未找到有效的 AK/SK 数据行（表头下方无数据）" >&2
    exit 1
  fi

  # 解析逗号分隔字段
  IFS=',' read -r -a fields <<< "$target_line"
  n=${#fields[@]}
  if [ "$n" -lt 2 ]; then
    echo "❌ 凭证解析失败：数据列数不足（至少需要 AK 和 SK 两列，当前列数: $n）" >&2
    exit 1
  fi

  # 无论是 2 列格式 (AK,SK) 还是 3 列格式 (Username,AK,SK)，倒数第二列为 AK，倒数第一列为 SK
  HW_ACCESS_KEY=$(echo "${fields[$((n-2))]}" | tr -d '[:space:]')
  HW_SECRET_KEY=$(echo "${fields[$((n-1))]}" | tr -d '[:space:]')
fi

# 支持从备用环境变量别名获取
HW_ACCESS_KEY="${HW_ACCESS_KEY:-${HUAWEI_AK:-${HUAWEICLOUD_SDK_AK:-}}}"
HW_SECRET_KEY="${HW_SECRET_KEY:-${HUAWEI_SK:-${HUAWEICLOUD_SDK_SK:-}}}"

# 若仍未设置，启动安全交互输入
if [ -z "${HW_ACCESS_KEY:-}" ]; then
  read -r -p "请输入 Access Key Id (AK): " HW_ACCESS_KEY
fi
if [ -z "${HW_SECRET_KEY:-}" ]; then
  read -r -s -p "请输入 Secret Access Key (SK，输入不显示): " HW_SECRET_KEY
  echo
fi

# 去除首尾空白
HW_ACCESS_KEY=$(echo "$HW_ACCESS_KEY" | tr -d '[:space:]')
HW_SECRET_KEY=$(echo "$HW_SECRET_KEY" | tr -d '[:space:]')

if [ -z "$HW_ACCESS_KEY" ] || [ -z "$HW_SECRET_KEY" ]; then
  echo "❌ 错误：AK 与 SK 均不能为空" >&2
  exit 1
fi

# 脱敏展示 AK
mask() {
  local s="$1"
  if [ "${#s}" -le 6 ]; then
    echo "****"
  else
    echo "${s:0:4}****${s: -2}"
  fi
}
echo "🔑 使用 AK: $(mask "$HW_ACCESS_KEY")"

# 调用接口封装
call() { # 参数: $1=method $2=path [$3=body]
  local method="$1"
  local path="$2"
  local body="${3:-}"
  local noproxy_flag=()

  if [ "$USE_NOPROXY" = 1 ]; then
    noproxy_flag=(--noproxy "*")
  fi

  local curl_cmd=(
    curl -sS -K -
    -X "$method"
    "${BASE}${path}"
    "${noproxy_flag[@]}"
    -A "HuaweiCloud-Devkit/${CLIENT_VERSION} (cli)"
    -H 'Content-Type: application/json'
    -H "X-HW-Client-Version: ${CLIENT_VERSION}"
    --connect-timeout 10
    --max-time 60
  )

  if [ -n "$body" ]; then
    curl_cmd+=(-d "$body")
  fi

  # 安全核心：凭证通过 stdin 传入 curl -K - 配置，避免在命令行与进程列表中泄露
  local resp
  resp=$(printf 'header = "X-HW-AK: %s"\nheader = "X-HW-SK: %s"\n' "$HW_ACCESS_KEY" "$HW_SECRET_KEY" | \
    "${curl_cmd[@]}" 2>&1) || {
    echo "{\"claimed\":false,\"message\":\"网络请求失败：$resp\"}"
    return 0
  }

  if [ -z "$resp" ]; then
    echo '{"claimed":false,"message":"服务器返回空响应"}'
  else
    echo "$resp"
  fi
}

# 从 JSON 提取指定字段（正则兼容不同空格与数据类型）
extract_field() { # 参数: $1=json $2=key
  local json="$1" key="$2"
  local val
  # 优先匹配带双引号的字符串值: "key": "value" 或 "key":"value"
  val=$(echo "$json" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -n 1)
  if [ -z "$val" ]; then
    # 匹配数值或布尔值: "key": 123 或 "key":true
    val=$(echo "$json" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\\([^,}\" ]*\\).*/\\1/p" | head -n 1)
  fi
  echo "$val"
}

# 格式化输出业务结果
explain() { # 参数: $1=name $2=response
  local name="$1" r="$2"
  echo "[$name] 原始返回：$r"

  # 兼容 "claimed": true 与 "claimed":true
  if echo "$r" | grep -Eq '"claimed"[[:space:]]*:[[:space:]]*true'; then
    local amount vid
    amount=$(extract_field "$r" "amount")
    vid=$(extract_field "$r" "voucherId")
    local extra=""
    if [ -n "$amount" ] && [ "$amount" != "0" ] && [ "$amount" != "null" ]; then
      extra="面额：${amount} 元"
    fi
    if [ -n "$vid" ] && [ "$vid" != "null" ]; then
      extra="${extra:+${extra}，}券号：${vid}"
    fi

    if [ -n "$extra" ]; then
      echo "[$name] ✅ 领取成功！$extra"
    else
      echo "[$name] ✅ 领取成功（或之前已领过）"
    fi
  elif echo "$r" | grep -q "HDKIT_CRED_INVALID"; then
    echo "[$name] ❌ AK/SK 无效：请检查是否复制完整、是否为主账号密钥（非IAM子账号）、密钥是否已在控制台被删除或禁用"
  elif echo "$r" | grep -q "额度已用完"; then
    echo "[$name] ⏳ 本月全平台额度已发完，下月 1 号 0 点再试"
  elif echo "$r" | grep -Eq "NOT_FOUND|下线"; then
    echo "[$name] ❌ 活动不存在或已下线"
  elif echo "$r" | grep -Eq "报名|资格|白名单|团队"; then
    echo "[$name] ❌ 没有资格：请确认已前往大赛页完成报名并创建或加入了参赛团队"
  else
    local msg
    msg=$(extract_field "$r" "message")
    if [ -n "$msg" ] && [ "$msg" != "null" ]; then
      echo "[$name] ⚠️ 未成功：$msg"
    else
      echo "[$name] ⚠️ 未成功，请查看上方原始返回信息"
    fi
  fi
}

# 仅查询状态模式
if [ "$STATUS_ONLY" = 1 ]; then
  r="$(call GET voucher/status)"
  echo "[激励券状态] 原始返回：$r"
  if echo "$r" | grep -Eq '"claimed"[[:space:]]*:[[:space:]]*true'; then
    echo "[激励券状态] ✅ 已领取过"
  elif echo "$r" | grep -Eq '"claimed"[[:space:]]*:[[:space:]]*false'; then
    local msg
    msg=$(extract_field "$r" "message")
    if echo "$r" | grep -q "未领取"; then
      echo "[激励券状态] 🎁 尚未领取，当前资格正常可领取！"
    elif [ -n "$msg" ] && [ "$msg" != "null" ]; then
      echo "[激励券状态] ℹ️ 未领取（$msg）"
    else
      echo "[激励券状态] 🎁 尚未领取，可尝试领取"
    fi
  else
    explain "激励券状态" "$r"
  fi
  exit 0
fi

# 执行领取
if [ -z "$ONLY" ] || [ "$ONLY" = "competition" ]; then
  explain "赛事券 200 元" "$(call POST competition/voucher/claim '{}')"
fi

if [ -z "$ONLY" ] || [ "$ONLY" = "incentive" ]; then
  explain "激励券 10 元" "$(call POST voucher/claim '{}')"
fi

echo
echo "👉 到账查看路径：华为云控制台 → 费用中心 → 优惠与折扣 → 优惠券"
echo "🔒 安全最佳实践：代金券到账后，建议立即前往「我的凭证 → 访问密钥」删除本次使用的临时 AK/SK！"

# 说话 Shuohua — Linux 版

Linux 语音转文字工具，使用 Qwen3-ASR 本地语音识别 + LLM 文本修正。

## 系统要求

- Ubuntu 22.04+ / x86_64
- NVIDIA GPU + CUDA
- X11 桌面 (GNOME / KDE)

## 安装

### 1. 系统依赖

```bash
sudo apt install xdotool xclip portaudio19-dev python3-dev
```

### 2. Python 依赖

```bash
cd ~/personal/shuohua/linux
pip install -r requirements.txt
```

## 使用

```bash
python -m shuohua
```

启动后：
1. 系统托盘出现图标（灰色圆 = 空闲）
2. **双击 Ctrl** 开始录音（图标变红）
3. **再次双击 Ctrl** 停止录音，自动转录并输入到当前光标位置
4. 若配置了 API Key，转录文本会自动修正（去除填充词）

## 配置

配置文件位于 `~/.config/shuohua/config.yaml`，首次运行自动创建。

可通过托盘菜单 "编辑设置..." 打开编辑。

```yaml
# 是否启用文本修正
correction_enabled: true

# LLM 提供商: deepseek / groq / custom
provider: deepseek

# DeepSeek
deepseek_api_key: ""

# Groq
groq_api_key: ""
groq_model: "llama-3.3-70b-versatile"

# 自定义 (OpenAI 兼容)
custom_endpoint: ""
custom_model: ""
custom_api_key: ""
```

## 开机自启（可选）

```bash
cp resources/shuohua.desktop ~/.config/autostart/
```

## 日志

运行日志输出到 `/tmp/shuohua.log`，可通过托盘菜单 "查看运行日志" 打开。

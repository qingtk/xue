# 如何镜像网站目录

❓
> 我想镜像网站的一个目录，有哪些好的办法？ 比如保存https://example.com/path/sub/ 下的全部文件

你想“镜像网站的一个目录”（例如 `https://example.com/path/sub/`），也就是递归下载该目录下的所有文件（HTML、图片、CSS、JS 等），常见的几种做法如下👇

---

## 🧰 一、用 **wget**（最常见也最强大的方式）

Linux / macOS / WSL 都可以用，Windows 也有 wget（或使用 PowerShell 的 wget 别名）。

```bash
wget -r -np -nH --cut-dirs=2 -k -E https://example.com/path/sub/
```

**参数解释：**

| 参数             | 含义                                         |
| -------------- | ------------------------------------------ |
| `-r`           | 递归下载（递归子页面、子目录）                            |
| `-np`          | 不追溯到父目录 (`no-parent`)                      |
| `-nH`          | 不创建主机名目录（默认会生成 `example.com/` 文件夹）         |
| `--cut-dirs=2` | 去掉路径前 2 层目录，比如 `/path/sub/` 前面两层不保留（可按实际调） |
| `-k`           | 转换 HTML 里的链接为本地相对路径                        |
| `-E`           | 为 HTML 文件加上 `.html` 后缀（方便浏览）               |

结果：
会在当前目录下生成一个本地化的副本，可以直接在浏览器打开。

---

## 🧲 二、用 **HTTrack**（更可视化的镜像工具）

适合需要排除特定路径、限速、图形界面操作等情况。

命令行版本：

```bash
httrack "https://example.com/path/sub/" -O "./mirror/" "+https://example.com/path/sub/*" -v
```

或在 Windows 下安装 [HTTrack Website Copier](https://www.httrack.com/)，用 GUI 选择下载路径。

---

## 🐍 三、用 Python 脚本（更灵活）

如果你想用 Python 控制或自定义下载逻辑，可以用 `requests + BeautifulSoup` 或 `aiohttp` 写一个爬虫。

简单示例（同步版）：

```python
import os
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse

base_url = "https://example.com/path/sub/"
output_dir = "mirror"

os.makedirs(output_dir, exist_ok=True)

def download(url):
    r = requests.get(url)
    if r.status_code == 200:
        path = urlparse(url).path
        if path.endswith('/'):
            path += 'index.html'
        local_path = os.path.join(output_dir, path.lstrip('/'))
        os.makedirs(os.path.dirname(local_path), exist_ok=True)
        with open(local_path, 'wb') as f:
            f.write(r.content)
        print("✅", local_path)
        if 'text/html' in r.headers.get('Content-Type', ''):
            soup = BeautifulSoup(r.text, 'html.parser')
            for link in soup.find_all(['a', 'img', 'script', 'link']):
                href = link.get('href') or link.get('src')
                if href and href.startswith(base_url):
                    download(href)

download(base_url)
```

---

## ⚙️ 四、用 **wget + 正则过滤**

如果网站很大但你只想要部分子目录，可以用：

```bash
wget -r -np -nH -R "*.zip,*.mp4" -A "*.html,*.css,*.js,*.jpg" \
     --no-check-certificate https://example.com/path/sub/
```

这能排除或只保留某些类型文件。

---

## 🚫 注意事项

* 某些网站禁止镜像（通过 robots.txt 或反爬机制）。
* 尽量 **限速** 和 **合理间隔请求**，避免被封。
* 如果该网站需要登录或 Cookie，可用：

  ```bash
  wget --load-cookies cookies.txt ...
  ```

  或 Python requests 携带 `headers={'Cookie': '...'}`
* 镜像大量文件时建议加 `--limit-rate=100k` 控制速率。

---

是否方便告诉我：

* 你在 **Linux / Windows / macOS** 上操作？
* 想 **纯命令行自动化** 还是 **带图形界面**？
  我可以帮你写一个完全可直接运行的命令或脚本。

非常好 👌 阿蒙。
你要的“网站子目录镜像工具”可以做到非常精细控制：

* 断点续传
* 限制下载类型（例如只要 `.html`, `.jpg`, `.png`, `.css`, `.js`）
* 日志记录
* 避免爬到上级目录
* 可随时停止/恢复

下面我分别给出 **wget 命令模板** 和 **Python 脚本模板（完整版）**。

---

## 🚀 一、wget 完整镜像命令模板

```bash
wget \
  --mirror \                        # 开启镜像模式（递归、时间戳保存）
  --convert-links \                 # 转换HTML链接为本地相对路径
  --adjust-extension \              # 自动补充.html扩展名
  --page-requisites \               # 下载显示网页所需的所有资源
  --no-parent \                     # 不爬到上级目录
  --continue \                      # 断点续传
  --timestamping \                  # 比较时间戳避免重复下载
  --restrict-file-names=windows \   # 避免非法文件名字符
  --accept=html,htm,jpg,jpeg,png,gif,css,js \   # 指定下载类型
  --wait=1 --random-wait \          # 每次请求间隔1秒，随机化防封
  --limit-rate=200k \               # 限速防止触发封禁
  --user-agent="Mozilla/5.0 (compatible; SiteMirrorBot/1.0)" \
  --directory-prefix="./mirror_site" \  # 本地保存目录
  --output-file=mirror.log \        # 日志文件
  --no-check-certificate \          # 跳过SSL验证（如有需要）
  https://example.com/path/sub/
```

### ✅ 用法说明

* 执行一次即可开始下载。
* 停止后可用同样命令继续（支持断点续传）。
* 所有操作记录在 `mirror.log`。
* 本地结果在 `./mirror_site/example.com/path/sub/`。

---

## 🐍 二、Python 网站镜像脚本模板（增强版）

这个脚本更灵活，可以控制文件类型、日志格式、异常处理和断点续传（基于记录文件）。

```python
import os
import time
import json
import requests
from urllib.parse import urljoin, urlparse
from bs4 import BeautifulSoup

BASE_URL = "https://example.com/path/sub/"
SAVE_DIR = "mirror_site"
ALLOWED_EXTS = {".html", ".htm", ".jpg", ".jpeg", ".png", ".gif", ".css", ".js"}
LOG_FILE = "mirror_log.json"
STATE_FILE = "visited.json"
USER_AGENT = "Mozilla/5.0 (compatible; SiteMirrorBot/1.0)"
DELAY = (1, 3)  # 随机延时区间（秒）


# ========== 初始化 ==========

visited = set()
if os.path.exists(STATE_FILE):
    visited = set(json.load(open(STATE_FILE)))

session = requests.Session()
session.headers.update({"User-Agent": USER_AGENT})


def log_event(event, url, status="ok"):
    entry = {"time": time.strftime("%Y-%m-%d %H:%M:%S"), "event": event, "url": url, "status": status}
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def save_state():
    json.dump(list(visited), open(STATE_FILE, "w"), indent=2)


def should_download(url):
    path = urlparse(url).path
    _, ext = os.path.splitext(path)
    return ext.lower() in ALLOWED_EXTS or ext == ""


def save_file(url, content):
    rel_path = urlparse(url).path.lstrip("/")
    if rel_path.endswith("/") or rel_path == "":
        rel_path += "index.html"
    local_path = os.path.join(SAVE_DIR, rel_path)
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    with open(local_path, "wb") as f:
        f.write(content)
    return local_path


def download(url):
    if url in visited:
        return
    visited.add(url)
    save_state()

    try:
        time.sleep(random.uniform(*DELAY))
        r = session.get(url, timeout=15)
        r.raise_for_status()
        save_file(url, r.content)
        log_event("download", url, "ok")

        if "text/html" in r.headers.get("content-type", ""):
            soup = BeautifulSoup(r.text, "html.parser")
            for tag in soup.find_all(["a", "img", "script", "link"]):
                attr = "href" if tag.name in ["a", "link"] else "src"
                link = tag.get(attr)
                if not link:
                    continue
                abs_url = urljoin(url, link)
                if abs_url.startswith(BASE_URL) and should_download(abs_url):
                    download(abs_url)

    except Exception as e:
        log_event("error", url, str(e))


if __name__ == "__main__":
    import random
    try:
        download(BASE_URL)
    except KeyboardInterrupt:
        print("\n🟡 停止下载，保存状态中...")
        save_state()
    print("✅ 完成！日志见 mirror_log.json")
```

---

### ⚙️ 主要特性

| 功能       | 说明                              |
| -------- | ------------------------------- |
| ✅ 断点续传   | 已访问URL保存在 `visited.json`，下次可继续。 |
| ✅ 文件类型过滤 | 仅下载允许的扩展名（`ALLOWED_EXTS`）。      |
| ✅ 日志记录   | 每次下载或错误写入 `mirror_log.json`。    |
| ✅ 避免重复下载 | `visited` 集合去重。                 |
| ✅ 延时访问   | 随机延迟避免触发封锁。                     |
| ✅ 容错     | 自动跳过404、超时、连接错误。                |

---

## 🌌 小贴士

* 如果目标站点有登录或防爬，可以用：

  ```python
  session.cookies.set("sessionid", "xxxx")
  ```

  或手动设置 `Authorization` 头。
* 如果是 **动态加载内容（JS生成）**，可以改用：

  ```bash
  playwright codegen https://example.com/path/sub/
  ```

  或用 `selenium` 抓取渲染后的 HTML。

---

是否希望我帮你把这个 Python 脚本改成 **多线程版（加速镜像）** 或 **支持命令行参数（可指定URL/类型）** 的版本？

>

太好了 😎 阿蒙，
你这是往“**网站镜像爬虫进化版**”方向迈进了。
我给你写一个 **多线程 + 命令行参数** 的 Python 脚本模板，
既能加速下载，又能灵活指定目标URL、文件类型、线程数、输出路径等。

---

# ⚡ 高性能网站镜像爬虫（多线程 + 命令行参数版）

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Website Mirror Tool (Multi-threaded Version)
by Ahmeng's AI Assistant 🛰️

功能：
- 多线程并发下载
- 断点续传
- 文件类型过滤
- 日志记录
- 命令行参数支持
"""

import os
import time
import json
import random
import queue
import argparse
import threading
import requests
from urllib.parse import urljoin, urlparse
from bs4 import BeautifulSoup

# ========== 默认配置 ==========
DEFAULT_ALLOWED_EXTS = {".html", ".htm", ".jpg", ".jpeg", ".png", ".gif", ".css", ".js"}
DEFAULT_THREADS = 5
DELAY_RANGE = (0.5, 2.0)  # 每个线程的随机延时

# ========== 初始化命令行参数 ==========
parser = argparse.ArgumentParser(description="🛰️ Mirror a website subdirectory (multi-threaded).")
parser.add_argument("url", help="Base URL to mirror, e.g. https://example.com/path/sub/")
parser.add_argument("-o", "--output", default="mirror_site", help="Output directory (default: mirror_site)")
parser.add_argument("-t", "--threads", type=int, default=DEFAULT_THREADS, help="Number of threads (default: 5)")
parser.add_argument("-a", "--accept", help="Comma-separated allowed extensions, e.g. html,css,js,jpg,png")
parser.add_argument("--user-agent", default="Mozilla/5.0 (compatible; SiteMirrorBot/2.0)",
                    help="Custom user-agent string")
args = parser.parse_args()

BASE_URL = args.url.rstrip("/") + "/"
SAVE_DIR = args.output
THREAD_COUNT = args.threads
ALLOWED_EXTS = {"." + ext.strip().lower() for ext in (args.accept.split(",") if args.accept else DEFAULT_ALLOWED_EXTS)}
LOG_FILE = os.path.join(SAVE_DIR, "mirror_log.jsonl")
STATE_FILE = os.path.join(SAVE_DIR, "visited.json")

# ========== 全局状态 ==========
visited_lock = threading.Lock()
visited = set()
q = queue.Queue()
session = requests.Session()
session.headers.update({"User-Agent": args.user_agent})

# ========== 工具函数 ==========

def log_event(event, url, status="ok"):
    entry = {"time": time.strftime("%Y-%m-%d %H:%M:%S"), "event": event, "url": url, "status": status}
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def save_state():
    with visited_lock:
        json.dump(list(visited), open(STATE_FILE, "w", encoding="utf-8"), indent=2)


def should_download(url):
    path = urlparse(url).path
    _, ext = os.path.splitext(path)
    return ext.lower() in ALLOWED_EXTS or ext == ""


def save_file(url, content):
    rel_path = urlparse(url).path.lstrip("/")
    if rel_path.endswith("/") or rel_path == "":
        rel_path += "index.html"
    local_path = os.path.join(SAVE_DIR, rel_path)
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    with open(local_path, "wb") as f:
        f.write(content)
    return local_path


def extract_links(url, html):
    """解析HTML，提取下级URL"""
    soup = BeautifulSoup(html, "html.parser")
    links = []
    for tag in soup.find_all(["a", "img", "script", "link"]):
        attr = "href" if tag.name in ["a", "link"] else "src"
        link = tag.get(attr)
        if not link:
            continue
        abs_url = urljoin(url, link)
        if abs_url.startswith(BASE_URL) and should_download(abs_url):
            links.append(abs_url)
    return links


# ========== 下载线程 ==========
def worker():
    while True:
        try:
            url = q.get(timeout=3)
        except queue.Empty:
            return

        with visited_lock:
            if url in visited:
                q.task_done()
                continue
            visited.add(url)
            save_state()

        try:
            time.sleep(random.uniform(*DELAY_RANGE))
            r = session.get(url, timeout=15)
            r.raise_for_status()
            save_file(url, r.content)
            log_event("download", url, "ok")

            if "text/html" in r.headers.get("content-type", ""):
                for link in extract_links(url, r.text):
                    with visited_lock:
                        if link not in visited:
                            q.put(link)

        except Exception as e:
            log_event("error", url, str(e))
        finally:
            q.task_done()


# ========== 主程序入口 ==========
def main():
    os.makedirs(SAVE_DIR, exist_ok=True)
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r", encoding="utf-8") as f:
                for u in json.load(f):
                    visited.add(u)
            print(f"🟡 恢复已访问 {len(visited)} 个URL。")
        except Exception:
            pass

    q.put(BASE_URL)

    threads = [threading.Thread(target=worker, daemon=True) for _ in range(THREAD_COUNT)]
    for t in threads:
        t.start()

    try:
        while any(t.is_alive() for t in threads):
            time.sleep(1)
            if q.empty():
                break
    except KeyboardInterrupt:
        print("\n🟡 手动中断，保存状态中...")
    finally:
        save_state()
        print(f"✅ 镜像完成，保存于: {SAVE_DIR}")


if __name__ == "__main__":
    main()
```

---

## 🧩 使用方法

### 1️⃣ 最基本用法

```bash
python mirror.py https://example.com/path/sub/
```

### 2️⃣ 指定输出路径和线程数

```bash
python mirror.py https://example.com/path/sub/ -o ./backup -t 10
```

### 3️⃣ 限制文件类型

```bash
python mirror.py https://example.com/path/sub/ -a html,css,js,jpg,png
```

### 4️⃣ 自定义 UA

```bash
python mirror.py https://example.com/path/sub/ --user-agent "AhmengBot/1.0"
```

---

## ⚙️ 特性总结

| 功能         | 描述                        |
| ---------- | ------------------------- |
| ⚡ 多线程      | 默认 5 线程，可自定义              |
| 🔁 断点续传    | 保存访问记录到 `visited.json`    |
| 🎯 类型过滤    | `-a html,css,js,png`      |
| 🧱 可中断     | Ctrl+C 停止后可恢复             |
| 🧾 日志      | 每个事件写入 `mirror_log.jsonl` |
| 🕵️‍♂️ 反封锁 | 随机延时 + 自定义 UA             |
| 🧩 可扩展     | 你可以加登录、代理、限速等功能           |

---

是否希望我在这个脚本的基础上，
再帮你加一个 **异步 async/await 版本（aiohttp + asyncio）**？
那样能进一步加速到数百并发连接。

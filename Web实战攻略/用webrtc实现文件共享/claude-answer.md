### **WebRTC 文件共享的核心是通过 `RTCDataChannel` 建立点对点连接，直接在浏览器间传输文件数据，无需服务器中转。**

下面是一个完整的实现思路与代码示例。

---

## **核心架构**

WebRTC 文件共享需要三个关键部分：

1. **信令服务器（Signaling Server）**：交换 SDP（会话描述）和 ICE 候选，用于建立连接。可以用 WebSocket 实现，连接建立后就不再需要它。
2. **RTCPeerConnection**：负责 P2P 连接的建立与维护。
3. **RTCDataChannel**：实际传输文件数据的通道，支持二进制传输。

---

## **完整实现**

### **1. 信令服务器（Node.js + WebSocket）**

```javascript
// server.js
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

const clients = new Map();

wss.on('connection', (ws) => {
  const id = Math.random().toString(36).substr(2, 9);
  clients.set(id, ws);
  ws.send(JSON.stringify({ type: 'id', id }));

  ws.on('message', (message) => {
    const data = JSON.parse(message);
    // 转发信令到目标客户端
    if (data.target && clients.has(data.target)) {
      clients.get(data.target).send(JSON.stringify({ ...data, from: id }));
    }
  });

  ws.on('close', () => clients.delete(id));
});

console.log('Signaling server running on ws://localhost:8080');
```

---

### **2. 前端核心逻辑**

#### **连接建立（WebRTC Peer Connection）**

```javascript
// webrtc.js
const ICE_SERVERS = {
  iceServers: [{ urls: 'stun:stun.l.google.com:19302' }]
};

let peerConnection = null;
let dataChannel = null;
let ws = null;
let myId = null;

// 初始化 WebSocket 信令
function initSignaling() {
  ws = new WebSocket('ws://localhost:8080');

  ws.onmessage = async ({ data }) => {
    const msg = JSON.parse(data);

    switch (msg.type) {
      case 'id':
        myId = msg.id;
        console.log('My ID:', myId);
        break;

      case 'offer':
        await handleOffer(msg);
        break;

      case 'answer':
        await peerConnection.setRemoteDescription(new RTCSessionDescription(msg.sdp));
        break;

      case 'ice-candidate':
        await peerConnection.addIceCandidate(new RTCIceCandidate(msg.candidate));
        break;
    }
  };
}

// 发起连接（发送方）
async function createOffer(targetId) {
  peerConnection = new RTCPeerConnection(ICE_SERVERS);
  setupICE(targetId);

  // 创建数据通道
  dataChannel = peerConnection.createDataChannel('fileTransfer');
  setupDataChannel(dataChannel);

  const offer = await peerConnection.createOffer();
  await peerConnection.setLocalDescription(offer);

  ws.send(JSON.stringify({
    type: 'offer',
    target: targetId,
    sdp: peerConnection.localDescription
  }));
}

// 接收连接（接收方）
async function handleOffer(msg) {
  peerConnection = new RTCPeerConnection(ICE_SERVERS);
  setupICE(msg.from);

  // 接收方监听数据通道
  peerConnection.ondatachannel = ({ channel }) => {
    dataChannel = channel;
    setupDataChannel(channel);
  };

  await peerConnection.setRemoteDescription(new RTCSessionDescription(msg.sdp));
  const answer = await peerConnection.createAnswer();
  await peerConnection.setLocalDescription(answer);

  ws.send(JSON.stringify({
    type: 'answer',
    target: msg.from,
    sdp: peerConnection.localDescription
  }));
}

// ICE 候选交换
function setupICE(targetId) {
  peerConnection.onicecandidate = ({ candidate }) => {
    if (candidate) {
      ws.send(JSON.stringify({
        type: 'ice-candidate',
        target: targetId,
        candidate
      }));
    }
  };
}
```

---

#### **文件发送（分片传输）**

大文件必须分片发送，因为 `RTCDataChannel` 单次消息有大小限制（通常 256KB）。

```javascript
const CHUNK_SIZE = 64 * 1024; // 64KB per chunk

async function sendFile(file) {
  // 先发送文件元信息
  dataChannel.send(JSON.stringify({
    type: 'file-meta',
    name: file.name,
    size: file.size,
    mimeType: file.type
  }));

  // 分片读取并发送
  let offset = 0;
  const reader = new FileReader();

  const readNextChunk = () => {
    const slice = file.slice(offset, offset + CHUNK_SIZE);
    reader.readAsArrayBuffer(slice);
  };

  reader.onload = (e) => {
    dataChannel.send(e.target.result); // 发送二进制数据
    offset += e.target.result.byteLength;

    // 更新进度
    const progress = Math.round((offset / file.size) * 100);
    updateProgress(progress);

    if (offset < file.size) {
      // 流量控制：等待缓冲区可用
      if (dataChannel.bufferedAmount < dataChannel.bufferedAmountLowThreshold) {
        readNextChunk();
      } else {
        dataChannel.onbufferedamountlow = () => {
          dataChannel.onbufferedamountlow = null;
          readNextChunk();
        };
      }
    } else {
      dataChannel.send(JSON.stringify({ type: 'file-end' }));
      console.log('File sent!');
    }
  };

  // 设置缓冲阈值，避免内存溢出
  dataChannel.bufferedAmountLowThreshold = 512 * 1024;
  readNextChunk();
}
```

---

#### **文件接收（重组数据）**

```javascript
let receivedMeta = null;
let receivedChunks = [];
let receivedSize = 0;

function setupDataChannel(channel) {
  channel.binaryType = 'arraybuffer';

  channel.onopen = () => console.log('DataChannel open!');

  channel.onmessage = ({ data }) => {
    if (typeof data === 'string') {
      const msg = JSON.parse(data);

      if (msg.type === 'file-meta') {
        // 接收文件元信息，准备接收
        receivedMeta = msg;
        receivedChunks = [];
        receivedSize = 0;
        console.log(`Receiving: ${msg.name} (${msg.size} bytes)`);
      } else if (msg.type === 'file-end') {
        // 文件接收完毕，合并并下载
        const blob = new Blob(receivedChunks, { type: receivedMeta.mimeType });
        downloadFile(blob, receivedMeta.name);
      }
    } else {
      // 接收二进制分片
      receivedChunks.push(data);
      receivedSize += data.byteLength;

      const progress = Math.round((receivedSize / receivedMeta.size) * 100);
      updateProgress(progress);
    }
  };
}

function downloadFile(blob, filename) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
```

---

#### **进度显示（HTML）**

```html
<!-- index.html -->
<input type="text" id="targetId" placeholder="对方的 ID" />
<button onclick="createOffer(document.getElementById('targetId').value)">连接</button>

<input type="file" id="fileInput" />
<button onclick="sendFile(document.getElementById('fileInput').files[0])">发送文件</button>

<progress id="progress" value="0" max="100"></progress>
<span id="progressText">0%</span>

<script>
function updateProgress(value) {
  document.getElementById('progress').value = value;
  document.getElementById('progressText').textContent = value + '%';
}
initSignaling();
</script>
```

---

## **关键注意事项**

**流量控制** 是最容易忽略的问题。必须检查 `dataChannel.bufferedAmount`，否则发送速度过快会导致内存爆满甚至崩溃。上面代码中通过 `bufferedAmountLowThreshold` 和 `onbufferedamountlow` 事件来实现背压控制。

**NAT 穿透** 方面，仅靠 STUN 服务器在某些对称型 NAT 网络下可能失败，生产环境建议额外部署 TURN 服务器（如 [coturn](https://github.com/coturn/coturn)）作为中继备选。

**大文件处理** 时，接收方将所有 chunk 存在内存数组里，对于超大文件（几 GB）会占用大量内存。进阶方案可以使用 [File System Access API](https://developer.mozilla.org/en-US/docs/Web/API/File_System_Access_API) 将分片直接写入磁盘，避免内存压力。

**安全性** 方面，WebRTC DataChannel 默认通过 DTLS 加密，传输本身是安全的，但信令服务器的通信建议也用 WSS（WebSocket over TLS）保护。
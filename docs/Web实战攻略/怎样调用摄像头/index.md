## 怎样在浏览器中调用摄像头？介绍一下相关API，给出多个示例代码

问题，这正是 **Web 多媒体 API** 的核心能力之一。现在主流浏览器里调用摄像头，**标准、可靠、唯一正确姿势**基本就是：
👉 **MediaDevices + getUserMedia**（再配合 `<video>`、`<canvas>` 等）

我按「**从入门到进阶**」给你捋一遍，顺手上多段**可直接跑的示例代码**。
https://chatgpt.com/share/69845e4e-8d88-800f-a217-b2a96257782d

https://chatgpt.com/c/698452d8-7a48-8331-9f4f-a29b572933a6
---

## 一、核心 API 全景图（先有个地图）

### 1️⃣ 关键对象

| API                      | 作用          |
| ------------------------ | ----------- |
| `navigator.mediaDevices` | 设备入口        |
| `getUserMedia()`         | 请求摄像头 / 麦克风 |
| `MediaStream`            | 摄像头输出的流     |
| `<video>`                | 播放摄像头画面     |
| `<canvas>`               | 截图 / 处理画面   |
| `enumerateDevices()`     | 列出所有摄像头     |
| `MediaRecorder`          | 录像          |

---

## 二、最基础：打开摄像头并显示到 `<video>`

### HTML

```html
<video id="camera" autoplay playsinline></video>
```

### JS（最小可用版）

```js
async function openCamera() {
  const stream = await navigator.mediaDevices.getUserMedia({
      video: true,
          audio: false
            });

              const video = document.getElementById('camera');
                video.srcObject = stream;
                }

                openCamera();
                ```

                ### ⚠️ 注意事项（很重要）

                * **必须 https**（或 `localhost`）
                * 用户会看到 **浏览器权限弹窗**
                * 手机端要加 `playsinline`，否则会强制全屏

                ---

                ## 三、进阶 1：指定分辨率 / 前后摄像头

                ### 1️⃣ 分辨率约束

                ```js
                navigator.mediaDevices.getUserMedia({
                  video: {
                      width: { ideal: 1280 },
                          height: { ideal: 720 }
                            }
                            });
                            ```

                            ### 2️⃣ 手机前后摄像头

                            ```js
                            navigator.mediaDevices.getUserMedia({
                              video: {
                                  facingMode: { exact: "environment" } // 后置
                                    }
                                    });
                                    ```

                                    | 值             | 含义    |
                                    | ------------- | ----- |
                                    | `user`        | 前置摄像头 |
                                    | `environment` | 后置摄像头 |

                                    ---

                                    ## 四、进阶 2：列出所有摄像头并让用户选择

                                    ### 获取设备列表

                                    ```js
                                    const devices = await navigator.mediaDevices.enumerateDevices();

                                    const cameras = devices.filter(d => d.kind === 'videoinput');
                                    console.log(cameras);
                                    ```

                                    返回示例：

                                    ```js
                                    [
                                      { deviceId: "abc", label: "HD Webcam", kind: "videoinput" },
                                        { deviceId: "def", label: "USB Camera", kind: "videoinput" }
                                        ]
                                        ```

                                        ### 选择指定摄像头

                                        ```js
                                        navigator.mediaDevices.getUserMedia({
                                          video: {
                                              deviceId: { exact: selectedDeviceId }
                                                }
                                                });
                                                ```

                                                👉 **多摄像头设备（笔电 + USB）必备**

                                                ---

                                                ## 五、进阶 3：拍照（摄像头截图）

                                                ### HTML

                                                ```html
                                                <video id="camera" autoplay></video>
                                                <canvas id="shot" width="640" height="480"></canvas>
                                                <button id="snap">拍照</button>
                                                ```

                                                ### JS

                                                ```js
                                                const video = document.getElementById('camera');
                                                const canvas = document.getElementById('shot');
                                                const ctx = canvas.getContext('2d');

                                                document.getElementById('snap').onclick = () => {
                                                  ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
                                                  };
                                                  ```

                                                  你现在已经可以：

                                                  * 人脸识别
                                                  * 扫码
                                                  * OCR
                                                  * 特效滤镜

                                                  ---

                                                  ## 六、进阶 4：录像（MediaRecorder）

                                                  ### 开始录像

                                                  ```js
                                                  const stream = await navigator.mediaDevices.getUserMedia({ video: true });
                                                  const recorder = new MediaRecorder(stream);

                                                  const chunks = [];
                                                  recorder.ondataavailable = e => chunks.push(e.data);

                                                  recorder.start();
                                                  ```

                                                  ### 停止并导出

                                                  ```js
                                                  recorder.stop();

                                                  recorder.onstop = () => {
                                                    const blob = new Blob(chunks, { type: 'video/webm' });
                                                      const url = URL.createObjectURL(blob);

                                                        const a = document.createElement('a');
                                                          a.href = url;
                                                            a.download = 'record.webm';
                                                              a.click();
                                                              };
                                                              ```

                                                              ---

                                                              ## 七、常见坑（踩过的人都懂）

                                                              ### ❌ 1. HTTP 页面

                                                              ```
                                                              DOMException: Only secure origins are allowed
                                                              ```

                                                              ✅ 解决：

                                                              * 用 `https`
                                                              * 或 `http://localhost`

                                                              ---

                                                              ### ❌ 2. iOS Safari 黑屏

                                                              解决方案：

                                                              ```html
                                                              <video autoplay muted playsinline></video>
                                                              ```

                                                              ---

                                                              ### ❌ 3. 用户拒绝权限

                                                              ```js
                                                              try {
                                                                await navigator.mediaDevices.getUserMedia({ video: true });
                                                                } catch (e) {
                                                                  alert("你拒绝了摄像头权限");
                                                                  }
                                                                  ```

                                                                  ---

                                                                  ## 八、你已经能做什么了？

                                                                  用这些 API，你可以直接做出：

                                                                  * 📷 网页相机
                                                                  * 🎥 Web 录像工具
                                                                  * 🧠 AI 摄像头（人脸 / 手势 / OCR）
                                                                  * 📱 H5 扫码支付
                                                                  * 🎮 Web AR / WebXR

                                                                  ---

                                                                  ## 九、如果你想继续「黑客级玩法」

                                                                  我可以继续带你玩：

                                                                  * ✅ Web + OpenCV.js 实时处理
                                                                  * ✅ WebRTC 摄像头推流
                                                                  * ✅ Three.js + 摄像头贴图
                                                                  * ✅ 权限劫持 & 反指纹（安全研究视角 😈）

                                                                  你想往 **实战应用** 还是 **安全 / 底层原理** 继续？

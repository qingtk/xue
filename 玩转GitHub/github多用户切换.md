1. 使用 GitHub CLI (`gh`) 的帳號切換功能 

GitHub 官方推出的命令行工具 `gh` 原生支持多帳號切換，非常直觀。 !
-   **操作步驟**：
    1.  **登錄多個帳號**：依次執行 `gh auth login` 並按照提示完成瀏覽器授權。
    2.  **查看狀態**：使用 `gh auth status` 查看目前登錄的所有帳號。
    3.  **切換帳號**：使用 `gh auth switch --user <username>` 即可一鍵切換當前活動帳號。
    4.  **自動配置**：執行 `gh auth setup-git`，它會自動幫你配置好當前倉庫的 Git 憑證。

2. 使用 GitHub Desktop 的帳號切換功能 
3. 参见 <https://docs.github.com/en/account-and-profile/how-tos/account-management/managing-multiple-accounts>
```
    #删除 github.com 的凭证
    echo "protocol=https`nhost=github.com" | git credential-manager erase
```

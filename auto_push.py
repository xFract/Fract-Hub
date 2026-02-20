import os
import subprocess
import sys
from datetime import datetime

def run_command(command, description):
    print(f"\n[INFO] {description} 実行中: {command}")
    try:
        result = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
        if result.stdout:
            print(result.stdout.strip())
        print(f"[OK] {description} に成功しました！")
        return True
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] {description} に失敗しました。 (Exit Code: {e.returncode})")
        if e.stdout:
            print("--- STDOUT ---")
            print(e.stdout.strip())
        if e.stderr:
            print("--- STDERR ---")
            print(e.stderr.strip())
        return False

def main():
    print("====================================")
    print("[INFO] Auto Build & Push Script")
    print("====================================")
    
    # スクリプトがあるディレクトリ（リポジトリのルート）に移動
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    # 1. build.py を呼び出してビルドを実行
    print("\n[STEP 1] プロジェクトのビルド")
    if not run_command("python build.py", "ビルドプロセスの実行"):
        print("\n[FAILED] ビルドに失敗したため、プッシュを中止します。")
        sys.exit(1)

    # 2. Gitステータスの確認（変更があるか）
    print("\n[STEP 2] 変更の確認")
    status = subprocess.run("git status --porcelain", shell=True, capture_output=True, text=True)
    if not status.stdout.strip():
        print("\n[WARN] 変更されたファイルがありません。何もコミット/プッシュされません。")
        sys.exit(0)

    # 3. git add
    print("\n[STEP 3] 変更をステージング (git add .)")
    if not run_command("git add .", "ステージング"):
        sys.exit(1)

    # コミットメッセージの生成（現在の日時）
    now = datetime.now()
    commit_msg = f"Auto-update: {now.strftime('%Y-%m-%d %H:%M:%S')}"
    
    # 4. git commit
    print(f"\n[STEP 4] コミット (メッセージ: '{commit_msg}')")
    if not run_command(f'git commit -m "{commit_msg}"', "コミット"):
        sys.exit(1)

    # 5. git push
    print("\n[STEP 5] リモートへのプッシュ (git push origin master)")
    if not run_command("git push origin master", "プッシュ"):
        print("\n[FAILED] プッシュに失敗しました。")
        sys.exit(1)

    print("\n[SUCCESS] 全てのプロセス（ビルド -> コミット -> プッシュ）が完了しました！")

if __name__ == "__main__":
    main()

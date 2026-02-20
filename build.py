import os
import subprocess
import sys

def run_command(command, description):
    print(f"\n[{description}] 実行中: {command}")
    try:
        # shell=True を指定してシステム側のパスを自動解決させる
        result = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
        if result.stdout:
            print(result.stdout.strip())
        print(f"[OK] {description} に成功しました！")
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] {description} に失敗しました。 (Exit Code: {e.returncode})")
        if e.stdout:
            print("--- STDOUT ---")
            print(e.stdout.strip())
        if e.stderr:
            print("--- STDERR ---")
            print(e.stderr.strip())
        sys.exit(1)

def main():
    print("[INFO] Fract-Hub のビルドを開始します...")
    
    # ワークスペース（このスクリプトがあるディレクトリ）に移動
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    if not os.path.exists("dist"):
        os.makedirs("dist")
        print("[INFO] 'dist' ディレクトリを作成しました。")

    # 1. Rojo Build
    run_command("rojo build -o dist/main.rbxm", "Rojoによるビルド")

    # 2. Lune Build (main.lua 生成)
    run_command("lune build", "LuneによるLuaファイルのバンドル")

    print("\n[SUCCESS] 全てのビルドプロセスが正常に完了しました！ `dist/main.lua` が更新されています。")

if __name__ == "__main__":
    main()

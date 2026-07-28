import argparse
import gc
import json
import subprocess
import sys
import time
from pathlib import Path

from jupyter_client import BlockingKernelClient


def project_name():
    root = Path.cwd().resolve()
    git_dir = root / ".git"
    while not git_dir.exists():
        parent = root.parent
        if parent == root:
            break
        root = parent
        git_dir = root / ".git"
    return root.name


def harness_dir():
    return Path("/tmp") / "harness" / project_name()


def get_kernel_file(session="default"):
    filename = "kernel.json" if session == "default" else f"kernel_{session}.json"
    return harness_dir() / filename


def start_kernel(session="default", use_repl=False, force=False):
    kernel_file = get_kernel_file(session).absolute()
    kernel_file.parent.mkdir(parents=True, exist_ok=True)
    if kernel_file.exists():
        if force:
            print(
                f"Force flag set; stopping existing session '{session}'...",
                file=sys.stderr,
            )
            stop_kernel(session=session)
        else:
            print(
                f"Error: Connection file already exists: {kernel_file}", file=sys.stderr
            )
            print(
                "Use --force to stop the existing session and restart.", file=sys.stderr
            )
            sys.exit(1)

    cmd = ["uv", "run", "python", "-m", "ipykernel_launcher", f"--f={kernel_file}"]

    print(f"Starting kernel '{session}'...", file=sys.stderr)

    subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    for _ in range(20):
        if kernel_file.exists():
            break
        time.sleep(0.5)

    if not kernel_file.exists():
        print(f"Error: Kernel failed to create {kernel_file}", file=sys.stderr)
        sys.exit(1)

    init_code = f"""
import os
import tempfile
from pathlib import Path

%load_ext autoreload
%autoreload 2

_harness_tmp = Path(tempfile.gettempdir()) / "harness" / "{project_name()}"
_harness_tmp.mkdir(parents=True, exist_ok=True)
os.environ["HARNESS_TMP"] = str(_harness_tmp)

print(f"Harness initialized. Temp plots directory: {{_harness_tmp}}")
"""
    send_code(init_code.strip(), session=session, silent=True)

    if use_repl:
        console(session=session)
    else:
        print(str(kernel_file))


def send_code(code, session="default", is_file=False, silent=False, detach=False):
    kernel_file = get_kernel_file(session)
    if not kernel_file.exists():
        print(
            f"Error: Connection file not found for session '{session}'", file=sys.stderr
        )
        sys.exit(1)

    if is_file:
        with open(code, "r") as f:
            code_to_run = f.read()
    else:
        code_to_run = code

    with open(kernel_file) as f:
        connection_info = json.load(f)

    client = BlockingKernelClient()
    client.load_connection_info(connection_info)
    client.start_channels()
    try:
        # store_history=True is key for SLIME-like sync with other consoles
        msg_id = client.execute(code_to_run, store_history=True)

        if detach:
            print(f"Detached: task submitted to session '{session}'", file=sys.stderr)
            return

        has_error = False
        finished = False
        idle_timeout = 120  # max seconds to wait for kernel to finish
        start = time.time()
        while not finished and (time.time() - start) < idle_timeout:
            try:
                msg = client.get_iopub_msg(timeout=0.5)
                msg_type = msg["msg_type"]
                content = msg["content"]
                parent_id = msg.get("parent_header", {}).get("msg_id")

                if parent_id != msg_id:
                    continue

                if msg_type == "stream":
                    out = sys.stdout if content["name"] == "stdout" else sys.stderr
                    print(content["text"], end="", flush=True, file=out)
                elif msg_type == "execute_result":
                    if not silent:
                        print(content["data"].get("text/plain", ""), flush=True)
                elif msg_type == "error":
                    has_error = True
                    print("\n".join(content["traceback"]), file=sys.stderr, flush=True)
                elif msg_type == "status":
                    if content["execution_state"] == "idle":
                        finished = True
            except Exception:
                # Fallback check for shell reply on timeout
                try:
                    reply = client.get_shell_msg(timeout=0.1)
                    if reply.get("parent_header", {}).get("msg_id") == msg_id:
                        if reply["content"]["status"] == "error":
                            has_error = True
                except Exception:
                    continue
    finally:
        client.stop_channels()
        time.sleep(0.05)
        gc.collect()

    if has_error:
        sys.exit(1)


def stop_kernel(session="default"):
    kernel_file = get_kernel_file(session)
    if not kernel_file.exists():
        print(f"No kernel file found for session '{session}'.", file=sys.stderr)
        return

    client = None
    try:
        with open(kernel_file) as f:
            connection_info = json.load(f)

        client = BlockingKernelClient()
        client.load_connection_info(connection_info)
        client.start_channels()
        client.shutdown()
    except Exception as e:
        print(f"Warning: Could not send graceful shutdown: {e}", file=sys.stderr)
    finally:
        if client is not None:
            try:
                client.stop_channels()
            except Exception:
                pass
        time.sleep(0.05)
        gc.collect()

    if kernel_file.exists():
        kernel_file.unlink()
        print(f"Removed {kernel_file}", file=sys.stderr)


def locate(session="default"):
    kernel_file = get_kernel_file(session)
    if kernel_file.exists():
        print(str(kernel_file.absolute()))
    else:
        print(f"Error: Session '{session}' not found", file=sys.stderr)
        sys.exit(1)


def show_path():
    print(Path(__file__).resolve())


def list_sessions():
    hdir = harness_dir()
    if not hdir.exists():
        print("No sessions found.")
        return

    sessions = []
    for f in sorted(hdir.iterdir()):
        if f.name.startswith("kernel") and f.suffix == ".json":
            name = f.name.removeprefix("kernel_").removesuffix(".json")
            if name == "kernel":
                name = "default"
            else:
                name = name
            alive = _check_alive(f)
            sessions.append((name, str(f), alive))

    if not sessions:
        print("No sessions found.")
        return

    print(f"{'Session':<12} {'Status':<8}  {'Connection File'}")
    print("-" * 60)
    for name, path, alive in sessions:
        status = "alive" if alive else "dead"
        print(f"{name:<12} {status:<8}  {path}")


def _check_alive(kernel_file):
    client = None
    try:
        with open(kernel_file) as f:
            connection_info = json.load(f)
        client = BlockingKernelClient()
        client.load_connection_info(connection_info)
        client.start_channels()
        msg_id = client.execute("import sys; sys.stdout.write('ping')", timeout=1)
        client.get_shell_msg(timeout=2)
        return True
    except Exception:
        return False
    finally:
        if client is not None:
            try:
                client.stop_channels()
            except Exception:
                pass


def console(session="default"):
    kernel_file = get_kernel_file(session)
    if not kernel_file.exists():
        print(
            f"Error: Session '{session}' not found. Did you start it?", file=sys.stderr
        )
        sys.exit(1)

    # Use jupyter console with flags to show output from other clients (like our 'send' command)
    cmd = [
        "uv",
        "run",
        "jupyter",
        "console",
        "--existing",
        str(kernel_file.absolute()),
        "--ZMQTerminalInteractiveShell.include_other_output=True",
        "--ZMQTerminalInteractiveShell.other_output_prefix=[Remote] ",
    ]

    print(
        f"Connecting to session '{session}'... (Press Ctrl-D to exit)", file=sys.stderr
    )
    try:
        subprocess.run(cmd)
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Agnostic Headless Kernel CLI")
    parser.add_argument("-s", "--session", default="default", help="Session name")
    subparsers = parser.add_subparsers(dest="command")

    start_p = subparsers.add_parser("start")
    start_p.add_argument(
        "--repl", action="store_true", help="Start with a visible interactive REPL"
    )
    start_p.add_argument(
        "-f", "--force", action="store_true", help="Stop existing session and restart"
    )

    subparsers.add_parser("stop")
    subparsers.add_parser("locate")
    subparsers.add_parser("console")
    subparsers.add_parser("path", help="Print the absolute path of this script")
    subparsers.add_parser("ps", help="List active kernel sessions")

    exec_p = subparsers.add_parser("exec", help="Execute a code string directly")
    exec_p.add_argument(
        "code", nargs="?", default="-", help="Code to execute, or '-' for stdin"
    )
    exec_p.add_argument(
        "-d",
        "--detach",
        action="store_true",
        help="Submit and return immediately (don't wait for result)",
    )

    send_p = subparsers.add_parser("send")
    send_p.add_argument(
        "source",
        nargs="?",
        default="-",
        help="File path, code string, or '-' for stdin",
    )
    send_p.add_argument("--code", action="store_true", help="Treat source as raw code")
    send_p.add_argument(
        "-d",
        "--detach",
        action="store_true",
        help="Submit and return immediately (don't wait for result)",
    )

    args = parser.parse_args()

    if args.command == "start":
        start_kernel(session=args.session, use_repl=args.repl, force=args.force)
    elif args.command == "stop":
        stop_kernel(session=args.session)
    elif args.command == "locate":
        locate(session=args.session)
    elif args.command == "console":
        console(session=args.session)
    elif args.command == "exec":
        if args.code == "-":
            source_code = sys.stdin.read()
        else:
            source_code = args.code
        send_code(source_code, session=args.session, is_file=False, detach=args.detach)
    elif args.command == "path":
        show_path()
    elif args.command == "ps":
        list_sessions()
    elif args.command == "send":
        if args.source == "-":
            source_code = sys.stdin.read()
            send_code(
                source_code, session=args.session, is_file=False, detach=args.detach
            )
        elif args.code:
            send_code(
                args.source, session=args.session, is_file=False, detach=args.detach
            )
        else:
            # Check if it's a file, otherwise treat as code if it doesn't look like a path
            path = Path(args.source)
            if path.exists() and path.is_file():
                send_code(
                    args.source, session=args.session, is_file=True, detach=args.detach
                )
            else:
                send_code(
                    args.source, session=args.session, is_file=False, detach=args.detach
                )
    else:
        parser.print_help()

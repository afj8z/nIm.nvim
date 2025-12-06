import glob
import os
import argparse


parser = argparse.ArgumentParser(
    prog="get recent screenshot",
    description="return most recent screenshot path",
    epilog="",
)

_ = parser.add_argument("screenshot_dir")
_ = parser.add_argument("destination_dir")
args = parser.parse_args()


def get_current_screenshot() -> str:
    list_of_files = glob.glob(args.screenshot_dir + "/*")
    latest_file = max(list_of_files, key=os.path.getctime)
    return latest_file


def move_screenshot():
    src = get_current_screenshot()

    try:
        fname = args.destination_dir + os.path.basename(src)
        # shutil.copyfile(src, fname)
    except:
        return print("false")
        raise
    else:
        print(fname)


if __name__ == "__main__":
    move_screenshot()

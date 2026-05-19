enable_venv(){
    local venv=$1
    local pip=$2
    local dir=$3
    # create a virtual env if not exsits
    if [ ! -d "$venv" ]; then
        python3 -m venv "$venv"
    fi

    # install all the libraries from requirements.txt
    "$pip" install -r "$dir/requirements.txt"

    source "$venv/bin/activate"
}
List of commands to execute on a remote machine for requirements.
-------------------------------------------------------------------

- sudo apt-get install libxrandr-dev
- Copy eeglab to remote machine (including the PREP plugin).
- Folder structure: within Documents, folders like (<number> is a number (e.g., EEG-code2) to ensure different machines work on different copies of the code):
    1) EEG-code<number>, containing the content of `scripts/`
    2) eeglab<number>, containing EEGLAB's code and PREP within the plugins.


Code execution.
----------------

- To execute the code, run the code from a `longtmux` session on OpenStack.
- The procedure is:
    ```
    ssh to machine
    longtmux
    tmux a
    <run code>
    ctrl+B, D
    exit from ssh session
    ```

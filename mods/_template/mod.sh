# shellcheck shell=bash
# Template for a new mod. Copy with:  ./scripts/new-mod.sh my-mod-name
#
# How a mod works
#   files/   -> copied into ~/.config/quickshell/ii  (same folder structure!)
#   bin/     -> copied into ~/.local/bin             (helper scripts)
#   hooks below run extra steps (patching a file, writing a config, ...)
#
# Every copied file is recorded, so `./install.sh --uninstall my-mod-name`
# removes it again and restores any file of yours that it replaced.
#
# Available inside hooks:
#   variables : QS_DIR  II_CONFIG  BIN_DIR  STATE_DIR  REPO_DIR
#   messages  : info  ok  warn  die
#   questions : ask "Question?" y|n        prompt_text "Label" "default"
#   checks    : need_cmd NAME   need_file PATH
#   files     : install_file MOD SRC TARGET    install_tree MOD SRC_DIR DEST_DIR
#   sidebar   : patch_delegate_chooser MOD ROLE Component copy_after_role
#               unpatch_delegate_chooser ROLE
#               config_toggle add|remove MOD TYPE [copy_after_type]

MOD=__MOD_NAME__

mod_description() {
  echo "Describe what __MOD_NAME__ does in one line"
}

# Optional. Runs first. Use it to check that the files you rely on exist.
mod_check() {
  :
}

# Optional. Runs after files/ and bin/ were copied.
mod_post_install() {
  :
}

# Optional. Runs before the copied files are removed. Undo what mod_post_install did.
mod_pre_uninstall() {
  :
}

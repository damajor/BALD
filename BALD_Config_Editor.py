import os
import sys
import re
import random
import ast
import datetime
from pathlib import Path
from textual import on
from textual.app import App, ComposeResult
from textual.containers import (
  Horizontal,
  VerticalScroll,
  Container,
  ScrollableContainer,
  HorizontalGroup,
  Vertical,
)
from textual.widgets import (
  Footer,
  Header,
  Button,
  MarkdownViewer,
  Label,
  TabbedContent,
  TabPane,
  ListView,
  ListItem,
  Select,
  SelectionList,
  Input,
  DirectoryTree,
)
from textual.widgets.selection_list import Selection
from textual.widget import Widget
from textual.binding import Binding
from textual.reactive import reactive
from markdown_it import MarkdownIt
from typing import Iterable

g_help_items = {}
g_help_type = {}
g_myconfig = {}
g_types = ("list", "mlist", "regex", "string", "integer", "ratio", "dirpath", "filepath")
g_config_file = "myconfig"
g_incontainer = None
g_container_restricted_items = [
  "HIST_LIB_DIR",
  "STATUS_FILE",
  "LOCAL_DB",
  "DOWNLOAD_DIR",
  "DEST_BASE_DIR",
  "DEBUG_USEAAXSAMPLE",
  "DEBUG_USEAAXCSAMPLE",
]
g_dir_prefix = ""

class DirectoryTreeDir(DirectoryTree):
  def filter_paths(self, paths: Iterable[Path]) -> Iterable[Path]:
    return [path for path in paths if path.is_dir()]

class Settings(Widget):
  """ Dynamic settings """

  item = None
  type = None
  values = None
  current_value = ""
  dorecompose = reactive(None, recompose=True)

  def compose(self) -> ComposeResult:
    if self.type not in g_types or (self.item is None and self.type is None):
      yield Label(f"Help only or unknown setting type ({self.type})")
      return
    yield HorizontalGroup(
      Label("Current value: "),
      Label(self.current_value, id="current_value")
    )
    with Vertical():
      if self.type == "list":
        with HorizontalGroup():
          yield Label("New value:", id="new_val")
          values = ast.literal_eval(self.values)
          if type(values) is list:
            tmp = [ (val, val) for val in values]
          elif type(values) is dict:
            values = values[g_myconfig[values["ref"]]]
            tmp = [ (val, val) for val in values]
          if self.current_value in values:
            yield Select(tmp, value=self.current_value, allow_blank=False, compact=True)
          else:
            yield Select(tmp, allow_blank=False, compact=True)
      elif self.type == "mlist":
        config_vals = self.current_value[1:-1].strip().split()
        allowed_vals = ast.literal_eval(self.values)
        selections = [ (str(val), val, str(val) in config_vals) for val in allowed_vals ]
        yield SelectionList(*selections)
      elif self.type == "regex":
        with HorizontalGroup():
          yield Label("New value:", id="new_val")
          if self.current_value:
            yield Input(self.current_value)
          else:
            yield Input(self.values)
      elif self.type == "string":
        with HorizontalGroup():
          yield Label("New value:", id="new_val")
          if self.current_value:
            yield Input(self.current_value)
          else:
            yield Input(self.values)
      elif self.type == "integer":
        with HorizontalGroup():
          yield Label("New value:", id="new_val")
          if self.current_value:
            yield Input(self.current_value, type="integer")
          else:
            yield Input(self.values)
      elif self.type == "ratio":
        with HorizontalGroup():
          yield Label("New value:", id="new_val")
          ratios = ['1/4', '1/3', '1/2', '2/3', '3/4', 'false']
          tmp = [ ('not_used/false' if val == 'false' else val, val) for val in ratios ]
          if self.current_value in ratios:
            yield Select(tmp, value=self.current_value, allow_blank=False, compact=True)
          else:
            yield Select(tmp, allow_blank=False, compact=True)
      elif self.type == "dirpath":
        path = Path(self.current_value)
        if not path.is_dir():
          path = Path("/")
        yield HorizontalGroup(
          Label("New value:", id="new_val"),
          Input(str(path), id="dti"),
        )
        yield Button("Open explorer", id="dpb", classes="explorer_button")
      elif self.type == "filepath":
        path = Path(self.current_value)
        if not path.is_file():
          path = Path("/")
        yield HorizontalGroup(
          Label("New value:", id="new_val"),
          Input(str(path), id="dti"),
        )
        yield Button("Open explorer", id="dfb", classes="explorer_button")
    yield DirectoryTree("/", id="dt_dfb")
    yield DirectoryTreeDir("/", id="dt_dpb")
    yield Button("Confirm new parameter value", id="apply")

class BALD_Config_Editor(App):
  """ A Textual app to create customized BALD Config """

  CSS_PATH = "BALD_Config_Editor.tcss"

  BINDINGS = [
    Binding(key="r", action="readme", description="Toggle readme"),
    Binding(key="c", action="readme_config", description="Toggle Config readme"),
    Binding(key="p", action="readme_podman", description="Toggle Podman readme"),
    Binding(key="e", action="readme_encoding", description="Toggle Encoding readme"),
    Binding(key="d", action="toggle_dark", description="Toggle light/dark mode"),
    Binding(key="q", action="quit", description="Quit"),
  ]

  def compose(self) -> ComposeResult:
    yield Header(id="header")
    yield Footer()
    overlay = MarkdownViewer("**Loading file !**", id="readme")#, show_table_of_contents=False)
    yield Container(
      overlay,
      id="overlay",
    )
    with ScrollableContainer():
      with TabbedContent():
        for section in g_help_items:
          if len(section["children"]) == 0:
            continue
          with TabPane(title="-"+section["title"]+"-", id="TB_"+section["title"].replace(" ", "_")):
            if len(section["children"][0]["children"]) == 0:
              with VerticalScroll():
                with Horizontal():
                  with ListView(id="LV_"+section["title"].replace(" ", "_")):
                    for sub_item in section["children"]:
                      yield ListItem(Label(sub_item["title"]))
                  yield MarkdownViewer(id="MD_"+section["title"].replace(" ", "_"), show_table_of_contents=False)
            else:
              with VerticalScroll():
                with Horizontal():
                  with ListView(id="LV_"+section["title"].replace(" ", "_")):
                    for sub_item in section["children"]:
                      for sub_sub_item in sub_item["children"]:
                        if len(sub_sub_item["children"]) == 0:
                          yield ListItem(Label(sub_sub_item["title"]))
                  yield MarkdownViewer(id="MD_"+section["title"].replace(" ", "_"), show_table_of_contents=False)
      yield Settings(id="settings")
      yield Horizontal(
        Button("Save 'myconfig'", id="bsc"),
        Button("Reload 'myconfig'", id="brc"),
      )

  @on(Button.Pressed, "#bsc")
  def save_config(self, event: Button.Pressed) -> None:
    config_file = f"{g_dir_prefix}{g_config_file}"
    if not g_incontainer and os.path.exists(config_file):
      base, ext = os.path.splitext(config_file)
      date_suffix = datetime.datetime.now().strftime('%Y%m%d%H%M%S')
      new_name = f"{config_file}-{date_suffix}"
      os.rename(config_file, new_name)
      self.notify(f"Old configuration file saved to {new_name}", timeout=3)
    with open(config_file, "w", encoding="utf-8") as config:
      for item in g_myconfig:
        if item in g_help_type and g_help_type[item]['type'] in ["regex", "dirpath", "filepath"]:
          config.write(item + "=\"" + g_myconfig[item] + "\"\n")
        else:
          config.write(item + "=" + g_myconfig[item] + "\n")
      self.notify("Settings written to configuration file.", timeout=3)

  @on(Button.Pressed, "#brc")
  def reload_config(self, event: Button.Pressed) -> None:
    global g_myconfig
    g_myconfig = parse_config(f"{g_dir_prefix}{g_config_file}")
    settings = self.query_one("#settings")
    self.set_item_type(settings.item)
    self.notify("Configuration reloaded.", timeout=3)

  @on(SelectionList.SelectedChanged)
  def update_selection_value(self, event: SelectionList.SelectedChanged) -> None:
    self.query_one("#settings").current_value = str(tuple(event.selection_list.selected)).replace(',', ' ')

  @on(Select.Changed)
  @on(Input.Changed)
  def update_input_and_select_value(self, event) -> None:
    self.query_one("#settings").current_value = event.value

  @on(Button.Pressed, "#apply")
  def apply_to_myconfig(self, event: Button.Pressed) -> None:
    settings = self.query_one("#settings")
    curr_val = settings.current_value if settings.current_value is not None else ""
    if settings.type == "regex":
      try:
        re.compile(curr_val)
        curr_val = "'" + curr_val.replace("'", "\\'") + "'"
        curr_val
      except re.error:
        self.notify("This is not a valid regex !!!", severity="error", timeout=10)
        return
    g_myconfig[settings.item] = curr_val
    settings.dorecompose = random.randrange(0, 100000)

  @on(Button.Pressed, "#dpb")
  @on(Button.Pressed, "#dfb")
  def butt(self, event: Button.Pressed) -> None:
    if self.query_one("#dt_" + event.button.id).display:
      self.query_one("#dt_" + event.button.id).display = False
    else:
      self.query_one("#dt_" + event.button.id).display = True

  @on(DirectoryTreeDir.DirectorySelected, "#dt_dpb")
  def update_dir(self, event: DirectoryTreeDir.DirectorySelected) -> None:
    self.query_one("#dti").value = str(event.path)
    self.query_one("#dt_dpb").display = False

  @on(DirectoryTree.FileSelected, "#dt_dfb")
  def update_file(self, event: DirectoryTree.DirectorySelected) -> None:
    if event.path.is_file():
      self.query_one("#dti").value = str(event.path)
    else:
      self.query_one("#dti").value = str(event.path) + "/status_file"
    self.query_one("#dt_dfb").display = False

  def on_mount(self) -> None:
    self.title = "BALD Config Editor"
    self.query_one("#overlay").display = False
    self.query_one("#readme").show_table_of_contents = False

  @on(TabbedContent.TabActivated)
  def tab_changed(self, event: TabbedContent.TabActivated) -> None:
    tbid = event.pane.id
    lv = self.query_one("#" + tbid.replace("TB_", "LV_"))
    self.set_item_type(lv.highlighted_child.children[0].content)

  @on(ListView.Highlighted)
  def update_markdown_help(self, event: ListView.Highlighted) -> None:
    """
    Update markdown for selected item.
    """
    item = event.item.children.displayed[0].content
    md = self.query_one("#"+event.list_view.id.replace("LV_", "MD_"), MarkdownViewer)
    if g_incontainer and item in g_container_restricted_items:
      help_content = """
        This setting is locked as you run inside container.
        Please refers to Podman readme for volume mapping.
      """
    else:
      help_content = self.find_leaf_content(g_help_items, item)
    md.document.update(help_content)
    self.set_item_type(item)

  def set_item_type(self, item_name) -> None:
    settings = self.query_one(Settings)
    if g_incontainer and item_name in g_container_restricted_items:
      settings.disabled = True
    else:
      settings.disabled = False
    settings.item = item_name
    settings.type = g_help_type[item_name]['type']
    settings.values = g_help_type[item_name]['values']
    settings.current_value = g_myconfig[item_name] if item_name in g_myconfig else None
    settings.dorecompose = random.randrange(0, 100000)

  def find_leaf_content(self, tree, leaf_title):
    """
    Recursively search the tree for a leaf node with the given title and return its markdown content.
    Returns None if not found or not a leaf.
    """
    for node in tree:
      # A leaf has content and no children
      if node.get('title') == leaf_title and node.get('content') is not None:
        return node['content']
      # Otherwise, search children recursively
      if node.get('children'):
        found = self.find_leaf_content(node['children'], leaf_title)
        if found is not None:
          return found
    return None

  async def action_readme(self) -> None:
    await self.query_one("#readme").document.load(f"{g_dir_prefix}README.md")
    self.toggle_overlay()

  async def action_readme_config(self) -> None:
    await self.query_one("#readme").document.load(f"{g_dir_prefix}README_Config_Parameters.md")
    self.toggle_overlay()

  async def action_readme_podman(self) -> None:
    await self.query_one("#readme").document.load(f"{g_dir_prefix}README_Podman_Walkthrough.md")
    self.toggle_overlay()

  async def action_readme_encoding(self) -> None:
    await self.query_one("#readme").document.load(f"{g_dir_prefix}README_Encoding_Options.md")
    self.toggle_overlay()

  def toggle_overlay(self) -> None:
    if self.query_one("#overlay").display:
      self.query_one("#overlay").display = False
    else:
      self.query_one("#overlay").display = True
      self.query_one("#readme").action_scroll_home()

###

def extract_heading_text(token):
  if token.type != 'inline':
    return ''
  parts = []
  for child in token.children or []:
    if child.type == 'text':
      parts.append(child.content)
    elif child.type == 'code_inline':
      parts.append(child.content)
    elif child.children:
      parts.append(extract_heading_text(child))
  return ''.join(parts)

def split_by_type(variable, types):
  for type in types:
    if variable.startswith(type):
      return type, variable[len(type):]
  return None, variable

def find_type(help_content: str) -> None:
  match = re.search(r'<!-- (.*?) -->', help_content, re.DOTALL)
  values = None
  if match:
    type, values = split_by_type(match.group(1).strip(), g_types)
    if type is not None:
      type = type
      values = values
    else:
      type = "none"
      values = None
  else:
    type = "none"
  return type, values

def parse_markdown_tree(md_text):
  md = MarkdownIt()
  tokens = md.parse(md_text)
  lines = md_text.splitlines()
  tree_stack = []
  root = {'title': None, 'level': 0, 'children': []}
  tree_stack.append((root, 0, -1))
  headings = []

  # Collect all headings with their start/end token indexes and line numbers
  i = 0
  while i < len(tokens):
    token = tokens[i]
    if token.type == 'heading_open':
      level = int(token.tag[1])
      next_token = tokens[i + 1] if i + 1 < len(tokens) else None
      title = extract_heading_text(next_token) if next_token and next_token.type == 'inline' else ''
      # Markdown-it tokens have .map = [start_line, end_line)
      start_line = token.map[0] if token.map else None
      headings.append({'title': title, 'level': level, 'start': i, 'children': [], 'content': None, 'start_line': start_line})
      i += 2
      while i < len(tokens) and tokens[i].type != 'heading_close':
        i += 1
      i += 1
    else:
      i += 1

  # Build the tree
  for idx, heading in enumerate(headings):
    while tree_stack and tree_stack[-1][1] >= heading['level']:
      tree_stack.pop()
    parent = tree_stack[-1][0]
    parent['children'].append(heading)
    tree_stack.append((heading, heading['level'], heading['start']))

  # Assign content to leaves only as markdown
  root_types = {}
  for idx, heading in enumerate(headings):
    next_idx = idx + 1
    is_leaf = True
    if next_idx < len(headings):
      if headings[next_idx]['level'] > heading['level']:
        is_leaf = False
    # Find markdown content lines between this heading and the next heading of same or higher level
    start_line = heading['start_line']
    if next_idx < len(headings):
      next_start_line = headings[next_idx]['start_line']
    else:
      next_start_line = len(lines)
    if is_leaf and start_line is not None:
      # Content is after heading line up to next heading
      heading['content'] = '\n'.join(lines[start_line + 1:next_start_line]).rstrip()
      type, vals = find_type(heading['content'])
      root_types[heading['title']] = { "type": type, "values": vals }
    else:
      heading['content'] = None

  return root['children'], root_types

def remove_unquoted_comment(line):
  """
  Removes comments not inside quotes, preserving all characters after '='.
  """
  in_single = False
  in_double = False
  for i, c in enumerate(line):
    if c == '"' and not in_single:
      in_double = not in_double
    elif c == "'" and not in_double:
      in_single = not in_single
    elif c == '#' and not in_single and not in_double:
      return line[:i].rstrip()
  return line

def is_enclosed_in_quotes(s):
  return (
    len(s) >= 2 and
    s[0] == s[-1] and
    s[0] in ("'", '"')
  )

def parse_config(filename):
  result = {}
  with open(filename) as f:
    for line in f:
      line = line.strip()
      if not line or line.startswith("#"):
        continue
      line = remove_unquoted_comment(line)
      if '=' not in line:
        continue
      key, value = line.split('=', 1)
      tmp = value.lstrip()
      if is_enclosed_in_quotes(tmp):
        tmp = ast.literal_eval(tmp)
      result[key.strip()] = tmp
  return result

def in_container() -> bool:
  value = os.environ.get("container")
  if value == "podman" or value == "docker":
    return True
  else:
    value = os.environ.get("INCONTAINER")
    if value == "true":
      return True
    else:
      return False

if __name__ == "__main__":
  g_incontainer = in_container()
  if g_incontainer:
    g_dir_prefix = "/BALD/"
    if not os.path.ismount(f"{g_dir_prefix}{g_config_file}"):
      print("ERROR: Missing volume mapping for 'myconfig'.")
      sys.exit(1)
  with open(f"{g_dir_prefix}README_Config_Parameters.md", 'r', encoding='utf-8') as f:
    md_text = f.read()
  g_help_items, g_help_type = parse_markdown_tree(md_text)
  g_myconfig = parse_config(f"{g_dir_prefix}{g_config_file}")
  app = BALD_Config_Editor()
  app.run(inline=False)
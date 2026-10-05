-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
vim.keymap.set("n", "<C-n>e", ":Neotree filesystem reveal left<CR>", {})

-- F5 automatic cpp run
vim.keymap.set("n", "<F5>", function()
  vim.cmd("w")
  vim.cmd("vsplit")
  vim.cmd("term cd %:p:h && clang++ -std=c++20 -Wall -Wextra %:t -o %:t:r && ./%:t:r")
  vim.cmd("startinsert")
end, { desc = "Compile and run C++" })

-- F6: zbuduj przez CMake cel, do ktorego nalezy biezacy plik, i uruchom go.
-- Cel odczytujemy z build/compile_commands.json, gdzie sciezka pliku .o ma postac
--   etap-01-pamiec/CMakeFiles/etap01_pamiec.dir/pamiec.cpp.o
--   ^-- podkatalog            ^-- nazwa celu
-- Binarka lezy wiec w build/<podkatalog>/<cel>. Dziala dla kazdego pliku w projekcie.
vim.keymap.set("n", "<F6>", function()
  vim.cmd("w")

  local file = vim.fn.expand("%:p")
  -- szukamy .git, a nie CMakeLists.txt: kazdy etap ma wlasny CMakeLists,
  -- wiec ten drugi znalazlby katalog etapu zamiast korzenia projektu
  local root = vim.fs.root(0, ".git")
  if not root then
    return vim.notify("Nie znalazlem korzenia projektu", vim.log.levels.ERROR)
  end
  local build = root .. "/build"

  local function znajdz_cel()
    local f = io.open(build .. "/compile_commands.json", "r")
    if not f then
      return nil
    end
    local ok, db = pcall(vim.json.decode, f:read("*a"))
    f:close()
    if not ok then
      return nil
    end
    for _, e in ipairs(db) do
      if e.file == file and e.output then
        local dir, cel, zrodlo = e.output:match("^(.*)CMakeFiles/([^/]+)%.dir/(.*)$")
        if cel then
          -- Binarka lezy w jednym z dwoch miejsc:
          --   build/<podkatalog>/<cel>      - cel z CMakeLists etapu (etap-00) albo brudnopis
          --   build/<katalog zrodla>/<cel>  - zadanie_N: cel zdefiniowany w glownym
          --     CMakeLists, obiekty w build/CMakeFiles/<cel>.dir/etap-NN/zadanie_N/,
          --     a binarka (RUNTIME_OUTPUT_DIRECTORY) w build/etap-NN/zadanie_N/
          local podkatalog = (dir:gsub("/$", ""))
          local katalog_zrodla = zrodlo:match("^(.*)/[^/]+$") or ""
          return cel, { podkatalog, katalog_zrodla }
        end
      end
    end
  end

  local cel, katalogi = znajdz_cel()
  if not cel then -- nowy plik: przekonfiguruj i sprobuj jeszcze raz
    vim.fn.system({ "cmake", "-B", build, "-S", root })
    cel, katalogi = znajdz_cel()
  end
  if not cel then
    return vim.notify("Ten plik nie nalezy do zadnego celu CMake", vim.log.levels.WARN)
  end

  local kandydaci = {}
  for _, k in ipairs(katalogi) do
    local exe = build .. "/" .. (k ~= "" and k .. "/" or "") .. cel
    table.insert(kandydaci, vim.fn.shellescape(exe))
  end
  local cmd = (
    "cmake --build %s --target %s && "
    .. '{ for exe in %s; do [ -x "$exe" ] && exec "$exe"; done; '
    .. "echo '(zbudowane - to biblioteka, nie ma czego uruchomic)'; }"
  ):format(vim.fn.shellescape(build), vim.fn.shellescape(cel), table.concat(kandydaci, " "))

  vim.cmd("vsplit | enew")
  vim.fn.jobstart(cmd, { term = true })
  vim.cmd("startinsert")
end, { desc = "CMake: zbuduj i uruchom cel dla tego pliku" })

sy on
set ts=4 sw=4 et ruler sm
set cinoptions=:0.5s=0.5sl1g0.5sh0.5sN-s
set wildmode=longest,list
set smartcase

"if &columns > 80
"  set columns=80
"endif

nmap  :set number!
nmap  :make

colors koehler

au BufNewFile,BufRead *.zsh setlocal filetype=zsh
au FileType c,cpp set cindent
au FileType go set makeprg=go\ build

set viminfo+=%

set cinoptions+=(0,Ws
set ttymouse=

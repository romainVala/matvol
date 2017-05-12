
suj = get_subdir_regex('/servernas/images/irene/imamemus','IMA')

[pp sujn] = get_parent_path(suj)

for k=1:length(sujn)
    sujn{k}(strfind(sujn{k},'_'))=' ';
end

for k =1:length(suj)

fonc = get_subdir_regex(suj(k),'gap$');

rp=get_subdir_regex_files(fonc,'^rp.*txt');
plot_realign(rp)
title(['rotation ' sujn{k}])
ylim([-0.05 0.05])
print( gcf, '-djpeg100','-r 300','-append',['rotation' sujn{k}]);
close

title(['translation ' sujn{k}])
ylim([-1 1])
print( gcf, '-djpeg100','-r 300','-append',['translation' sujn{k}]);
close

end


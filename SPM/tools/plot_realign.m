function plot_realign(dr)

if nargin==0
  P = spm_select([1 Inf],'dir','select EPI directorie','',pwd);
  dr = get_subdir_regex_files(cellstr(P),{'^rp.*txt','^real.*txt'});
end


l=[];

for k=1:length(dr)
  ll=load(dr{k});
  l=[l;ll];
end

figure

plot(l(:,1:3))
title('translation')

figure
plot(l(:,4:6))

title('rotation')




function o = get_last_modif_dir(indir)


  d=dir(indir);
d(1:2)=[];

for k=1:length(d)
	dn(k) = d(k).datenum;
end

[i j ] =max(dn) ;

  o = fullfile(indir,d(j).name);

function dim4 = get_volume_dim4(ff)


command = sprintf('sh -c ". ${FSLDIR}/etc/fslconf/fsl.sh; $FSLDIR/bin/fslhd %s |grep dim4;"\n', ...
    ff);

[aa bb] = system(command)


ii=findstr(bb,sprintf('\n'))

dim4 = str2num(bb(5:ii));



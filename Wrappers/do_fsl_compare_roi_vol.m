function [voli ] = do_fsl_compare_roi_vol(f)
%


for k=1:length(f)

    ff= cellstr(char(f(k)));
    vol = do_fsl_getvol(ff);
    
    tmp=tempname;
    
    fo = do_fsl_mult(ff,tmp);
    
    volinterp = do_fsl_getvol(tmp);
    
    voli(k,1)  = volinterp(1,1) ./ vol(1,1);
    voli(k,2)  = volinterp(1,1) ./ vol(2,1);
    
    do_delete(fo,0)
    
end



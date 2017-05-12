function hdr_restore_original_orientation(v)
 
v = cellstr(char(v));

for k = 1:length(v)
    
  h=spm_vol(v{k});

  [Y] = spm_read_vols(h);
    
  if ~strcmp(h.private.mat0_intent,'Scanner')
 	error('already moved twice check %s',h.fname)
  end
  
  if strcmp(h.private.mat_intent,'Scanner')
     fprintf('skiping %s because already in Scanner space',h.fname)
  else

    h.mat = h.private.mat0;
    h.private.mat = h.private.mat0;
    h.private.mat_intent=h.private.mat0_intent;
  
    rrr_write_vol(h,Y);
  end

end



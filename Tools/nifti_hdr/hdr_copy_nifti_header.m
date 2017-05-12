function hdr_copy_nifti_header(v1,v2,ask)
%hdr_copy_nifti_header(v1,v2)
%where v1 is the images to changed
%and v2 is the references
%v1 an v2 should have the same dimention

if ~exist('ask','var')
    ask = 1;
end

if ~exist('v1')
  v1 = spm_select([1 inf],'image','select images to change header','',pwd);
end
if ~exist('v2')
  v2 = spm_select([1 1],'image','select images for the reference header','',pwd);
end

if iscell(v2)
  
  fprintf('reference header will be %s\n',v2{1})
  if ask
      d=  input('continue ?\n','s');
  end
  
  if length(v2)~=length(v1)
    error('inputs should have the same length\n');
  end
  for ksuj=1:length(v2)
    h1 = spm_vol(v1{ksuj});
    h2 =  nifti_spm_vol(v2{ksuj});
    if length(h2)>1, h2 = h2(1);end
    
    for k=1:length(h1)

      [Y] = spm_read_vols(h1(k));
    
      h2.fname = h1(k).fname;
      h2.pinfo = h1(k).pinfo;
      h2.dt = h1(k).dt;
      rrr_write_vol(h2,Y);
    end
    
  end
  
else
  
  h1 = spm_vol(v1);
  h2 = spm_vol(v2);

  for k=1:length(h1)

    [Y] = spm_read_vols(h1(k));
    
    h2.fname = h1(k).fname;
    h2.pinfo = h1(k).pinfo;
    h2.dt = h1(k).dt;
   
    rrr_write_vol(h2,Y);

  end
  
end





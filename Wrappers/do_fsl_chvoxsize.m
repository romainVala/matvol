function do_fsl_chvoxsize(f)

 for k=1:length(f)
    
    cmd = sprintf('fslorient -getsform %s ',f{k});
    [a,b]=unix(cmd);
     bn=str2num(b);
     fprintf('changing x10  %f\n',bn([1 6 11])); 

     bn(1) = 10*bn(1);
     bn(6) = 10*bn(6);
     bn(11) = 10*bn(11);
     
     cmd = sprintf('fslorient -setsform %s %s ',num2str(bn),f{k});
     unix(cmd)

         cmd = sprintf('fslorient -getqform %s ',f{k});
    [a,b]=unix(cmd);
     
    bn=str2num(b)
     fprintf('changing x10  %f\n',bn([1 6 11])); 

     bn(1) = 10*bn(1);
     bn(6) = 10*bn(6);
     bn(11) = 10*bn(11);
     
     cmd = sprintf('fslorient -setqform %s %s ',num2str(bn),f{k});
     unix(cmd)

  end
  
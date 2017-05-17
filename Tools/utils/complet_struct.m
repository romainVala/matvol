function so = complet_struct(s,sd)

fi=fieldnames(sd);

so=s;

for k=1:length(fi)
  if ~isfield(s,fi{k})
    cc=getfield(sd,fi{k});
    so = setfield(so,fi{k},cc);
  end
  
end

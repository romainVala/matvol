function methods( self )
%METHODS prints the methods of the object

class_name = class( self );
class_dir  = fileparts( which( class_name ) );
class_meth = dir(class_dir);
class_meth = class_meth(3:end); % remoce . and ..
class_meth = {class_meth.name};
class_meth = regexprep(class_meth,'\.m','');

sc_names   = superclasses(class_name);

sc1_dir     = fileparts( which( sc_names{1} ) );
sc1_meth    = dir(sc1_dir);
sc1_meth    = sc1_meth(3:end); % remoce . and ..
sc1_meth    = {sc1_meth.name};
sc1_meth    = regexprep(sc1_meth,'\.m','');

sc2_dir     = fileparts( which( sc_names{2} ) );
sc2_meth    = dir(sc2_dir);
sc2_meth    = sc2_meth(3:end); % remoce . and ..
sc2_meth    = {sc2_meth.name};
sc2_meth    = regexprep(sc2_meth,'\.m','');

fprintf('----- \n')
fprintf('Class %s methods are : \n', upper(class_name))
fprintf('%s \n', class_meth{:})

fprintf('---------- \n')
fprintf('Superclass %s methods are : \n', upper(sc_names{1}))
fprintf('%s \n', sc1_meth{:})

fprintf('---------- \n')
fprintf('Superclass %s methods are : \n', upper(sc_names{2}))
fprintf('%s \n', sc2_meth{:})

end % functon

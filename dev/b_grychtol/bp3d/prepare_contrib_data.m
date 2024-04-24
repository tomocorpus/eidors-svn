path = 'stl';
vessels = {'Aorta','IVC','SVC','PA', 'LSPV', 'LIPV','RSPV','RIPV'};

rmbnd = @(x) rmfield(x, 'boundary');
for cname = vessels
    tmp = struct();
    name = cname{1};
    tmp.inner = rmbnd(stl_read([path filesep  name ' inner.stl']));
    tmp.outer = rmbnd(stl_read([path filesep  name ' outer.stl']));
    tmp.ring  = rmbnd(stl_read([path filesep  name ' ring.stl']));
    tmp.cap   = rmbnd(stl_read([path filesep  name ' cap.stl']));
    eval(sprintf('%s = tmp; clear tmp;',name));
end

%%
organs = {'Heart shell', 'Blood right', 'Blood left', ...
            'Lung right', 'Lung left', 'Trachea'};
orgnames = genvarname(organs);

for i = 1:numel(organs)
    tmp = struct();
    name = organs{i};
    tmp = rmbnd(stl_read([path filesep  name '.stl']));
    eval(sprintf('%s = tmp; clear tmp;',orgnames{i}));
end
%%
save('bp3d_organs',vessels{:}, orgnames{:})
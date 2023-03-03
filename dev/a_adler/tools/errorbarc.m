function hh=errorbarc(x,y,e1,e2,varargin)
% ERRORBARC: Coloured errorbar region
% hh=errorbarc(x,y,eneg,epos,varargin)

% TODO:
%  - Handle options for fill
%  - Handle Nan

% (C) 2023 A Adler: License GPL v2 or v3
  if nargin<=3; e2 = e1; end
  if isempty(e2); e2 = e1; end
  if size(x,1)==1; x=x.'; end
  if size(y,1)==1; y=y.'; end
  holder = ishold();
  if ~holder; cla; end
  hh= plot(x,y,varargin{:});

  hold on
  xx = [x;flipud(x)];
  for i = 1:length(hh)
    clr = get(hh(i),'Color');
    clr = 1 - (1 - clr) * .2;
    yy = [   y(:,i)-e1(:,i); ...
      flipud(y(:,i)+e2(:,i)) ];
    hi = fill(xx,yy,clr);
    set(hi,'EdgeColor','none');
    uistack( hi, 'bottom');
  end
  if ~holder; hold off; end

  if nargout==0; clear hh; end


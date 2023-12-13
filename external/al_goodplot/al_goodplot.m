function [h, mu, sigma, q, notch] = al_goodplot(x, pos, boxw, col, type, bw, p, jitw)
% Violin and box plots for visualization of data distribution.
%
%   Inputs:
%     - x: NxP, data (P plots) (sample data if empty).
%     - pos: 1xP, position of the graphs in x-axis, default: 1.
%     - boxw: width of the graphs, default: 0.5.
%     - col: Px3 or 1x3, colors of the graphs. default: current color.
%     - type: laterality of the graph, 'left', 'right', 'bilateral' (default), or display manual: 'man'.
%     - bw: 1xP or 1x1, width of the window for kernel density. default: matlab default.
%     - p: increment for parzen (use the same p for 2 plots to be compared
%     to enforce the same area.). default: std/1000
%     - jitw: jitter width for scatter plot: default 0.
%
%   Outputs:
%     - h: figure handle
%     - mu: mean
%     - sigma: standard deviation
%     - q: quantiles (0 1/4 1/2 3/4 1 1/10 9/10 1/100 99/100)
%     - notch: 95% confidence interval for median


% Parse inputs and set default values

if nargin<5 || isempty(type)
    type='bilateral';
end
if nargin<4 || isempty(col)
    colorOrder = get(gca, 'ColorOrder');
    col=colorOrder(mod(length(get(gca, 'Children')), size(colorOrder, 1))+1, :);
end
if nargin<3 || isempty(boxw)
    boxw=0.5;
end
if nargin<1 || isempty(x)
    type='man';
    % Example data for manual display
    rng(1)
    x=[4+randn(100,1); 8+3*randn(100,1)];
end
if nargin<2 || isempty(pos)
    pos=1:size(x,2);
end
if nargin<7 || isempty(p)  
    p=std(x(:))/1000;
end
if nargin<8 || isempty(jitw)  
    jitw=0;
end

u=0.9*min(x(:)):p:1.1*max(x(:));

h=cell(1,size(x,2));
mu=zeros(1,size(x,2));
sigma=zeros(1,size(x,2));
q=zeros(9,size(x,2));
notch=zeros(2,size(x,2));
if size(x,1)==1, x=x'; end
if size(x,2)>1 && size(pos,1)==1, pos=repmat(pos,1,size(x,2)); end
if size(x,2)>1 && size(col,1)==1, col=repmat(col,size(x,2),1); end
if size(x,2)>1 && size(boxw,1)==1, boxw=repmat(boxw,1,size(x,2)); end

for i=1:size(x,2)
    % Compute statistics useful to display
    mu(i)=mean(x(:,i));
    sigma(i)=std(x(:,i));
    q(:,i)=al_quantile(x(:,i),[0 1/4 1/2 3/4 1 1/10 9/10 1/100 99/100]);
    notch(:,i)=[q(3,i)-1.57*(q(4,i)-q(2,i))/sqrt(size(x,1)) q(3,i)+1.57*(q(4,i)-q(2,i))/sqrt(size(x,1))];

    % Compute kernel density
    uc=u(u>q(8,i) & u<q(9,i));
    if nargin<6 || isempty(bw)
        f=[0 al_parzen(x(:,i), uc) 0];
    else
        f=[0 al_parzen(x(:,i), uc, bw(i)) 0];
    end
    uc=[q(8,i) uc q(9,i)]; %#ok<AGROW>
    f=boxw(i)*2200*p*f/length(x);
    
    % Plots
    h{i}=gcf;
    switch type
        case {'bilateral', 'man'}
            scatter(pos(i)*ones(size(x(:,i)))+jitw*(rand(size(x(:,i)))-0.5),x(:,i),10,col(i,:),'filled');
            hold on
            patch([pos(i)-f fliplr(pos(i)+f)], [uc fliplr(uc)], 0.97*col(i,:),'edgecolor','none','facealpha',0.3)
            patch([pos(i)+boxw(i)/2 pos(i)+boxw(i)/2 pos(i)+boxw(i)/4 pos(i)+boxw(i)/2 pos(i)+boxw(i)/2 pos(i)-boxw(i)/2 pos(i)-boxw(i)/2 pos(i)-boxw(i)/4 pos(i)-boxw(i)/2 pos(i)-boxw(i)/2], [q(2,i) notch(1,i) q(3,i) notch(2,i) q(4,i) q(4,i) notch(2,i) q(3,i) notch(1,i) q(2,i)], 0.97*col(i,:),'edgecolor','none','facealpha',0.5,'HandleVisibility','off')
            patch([pos(i)-boxw(i)/8 pos(i)+boxw(i)/8 pos(i)+boxw(i)/8 pos(i)-boxw(i)/8 pos(i)-boxw(i)/8], [mu(i)-sigma(i) mu(i)-sigma(i) mu(i)+sigma(i) mu(i)+sigma(i) mu(i)-sigma(i)], col(i,:),'edgecolor','none','facealpha',0.35,'HandleVisibility','off')
            plot([pos(i)-boxw(i)/4 pos(i)+boxw(i)/4], [q(3,i) q(3,i)],'color',col(i,:)/2,'linewidth',1,'HandleVisibility','off')
            plot(pos(i), mu(i),'*','color',col(i,:)/2,'linewidth',1,'HandleVisibility','off')
            
            if strcmp(type, 'man')
                % Display graph documentation
                pu=floor(mean(find(uc>q(4,i) & uc<q(7,i))));
                plot([pos(i)+f(pu),pos(i)+1.2*boxw(i)], [uc(pu), uc(pu)],':','color','k');
                text(pos(i)+1.2*boxw(i), uc(pu),' kernel density','clipping', 'on');
                plot([pos(i)+boxw(i)/2,pos(i)+1.2*boxw(i)], [notch(1,i), notch(1,i)],':','color','k')
                text(pos(i)+1.2*boxw(i), notch(1,i),' notch inf., 95% conf. median');
                plot([pos(i)+boxw(i)/2,pos(i)+1.2*boxw(i)], [notch(2,i), notch(2,i)],':','color','k')
                text(pos(i)+1.2*boxw(i), notch(2,i),' notch sup., 95% conf. median');
                plot([pos(i)+boxw(i)/2,pos(i)+1.2*boxw(i)], [q(2,i), q(2,i)],':','color','k')
                text(pos(i)+1.2*boxw(i), q(2,i),' 1st quartile, q(0.25)');
                plot([pos(i)+boxw(i)/2,pos(i)+1.2*boxw(i)], [q(4,i), q(4,i)],':','color','k')
                text(pos(i)+1.2*boxw(i), q(4,i),' 3rd quartile, q(0.75)');
                plot([pos(i)+boxw(i)/4,pos(i)+1.2*boxw(i)], [q(3,i), q(3,i)],':','color','k')
                text(pos(i)+1.2*boxw(i), q(3,i),' median, q(0.5)');
                plot([pos(i)+boxw(i)/8,pos(i)+1.2*boxw(i)], [mu(i)-sigma(i), mu(i)-sigma(i)],':','color','k')
                text(pos(i)+1.2*boxw(i), mu(i)-sigma(i),' mean - standard deviation');
                plot([pos(i)+boxw(i)/8,pos(i)+1.2*boxw(i)], [mu(i)+sigma(i), mu(i)+sigma(i)],':','color','k')
                text(pos(i)+1.2*boxw(i), mu(i)+sigma(i),' mean + standard deviation');
                plot([pos(i)+f(2),pos(i)+1.2*boxw(i)], [q(8,i), q(8,i)],':','color','k')
                text(pos(i)+1.2*boxw(i), q(8,i),' 1st percentile, q(0.01)');
                plot([pos(i)+f(length(f)-1),pos(i)+1.2*boxw(i)], [q(9,i), q(9,i)],':','color','k')
                text(pos(i)+1.2*boxw(i), q(9,i),' 99th percentile, q(0.99)');
                plot([pos(i),pos(i)+1.2*boxw(i)], [mu(i), mu(i)],':','color','k')
                text(pos(i)+1.2*boxw(i), mu(i),' mean');
                plot([pos(i),pos(i)+1.2*boxw(i)], [q(5,i), q(5,i)],':','color','k')
                text(pos(i)+1.2*boxw(i), q(5,i),' raw data');
                plot(pos(i)+3*boxw(i),0)
            end
            
        case 'left'
            scatter((pos(i)-boxw(i)/40)*ones(size(x(:,i)))-jitw*0.25*rand(size(x(:,i))),x(:,i),10,col(i,:),'filled');
            hold on
            patch(pos(i)-f, uc, 0.97*col(i,:),'edgecolor','none','facealpha',0.3,'HandleVisibility','off')
            patch([pos(i) pos(i)-boxw(i)/2 pos(i)-boxw(i)/2 pos(i)-boxw(i)/4 pos(i)-boxw(i)/2 pos(i)-boxw(i)/2 pos(i) pos(i)], [q(2,i) q(2,i) notch(1,i) q(3,i) notch(2,i) q(4,i) q(4,i) q(2,i)], 0.97*col(i,:),'edgecolor','none','facealpha',0.5,'HandleVisibility','off')
            patch([pos(i)-boxw(i)/8 pos(i) pos(i) pos(i)-boxw(i)/8 pos(i)-boxw(i)/8], [mu(i)-sigma(i) mu(i)-sigma(i) mu(i)+sigma(i) mu(i)+sigma(i) mu(i)-sigma(i)], col(i,:),'edgecolor','none','facealpha',0.35,'HandleVisibility','off')
            plot([pos(i)-boxw(i)/4 pos(i)], [q(3,i) q(3,i)],'color',col(i,:)/2,'linewidth',1.5,'HandleVisibility','off')
            plot(pos(i)-boxw(i)/20, mu(i),'*','color',col(i,:)/2,'linewidth',1,'HandleVisibility','off')
            
        case 'right'
            scatter((pos(i)+boxw(i)/40)*ones(size(x(:,i)))+jitw*0.25*rand(size(x(:,i))),x(:,i),10,col(i,:),'filled');
            hold on
            patch(pos(i)+f, uc, 0.97*col(i,:),'edgecolor','none','facealpha',0.3,'HandleVisibility','off')
            patch([pos(i) pos(i)+boxw(i)/2 pos(i)+boxw(i)/2 pos(i)+boxw(i)/4 pos(i)+boxw(i)/2 pos(i)+boxw(i)/2 pos(i) pos(i)], [q(2,i) q(2,i) notch(1,i) q(3,i) notch(2,i) q(4,i) q(4,i) q(2,i)], 0.97*col(i,:),'edgecolor','none','facealpha',0.5,'HandleVisibility','off')
            patch([pos(i)+boxw(i)/8 pos(i) pos(i) pos(i)+boxw(i)/8 pos(i)+boxw(i)/8], [mu(i)-sigma(i) mu(i)-sigma(i) mu(i)+sigma(i) mu(i)+sigma(i) mu(i)-sigma(i)], col(i,:),'edgecolor','none','facealpha',0.35,'HandleVisibility','off')
            plot([pos(i)+boxw(i)/4 pos(i)], [q(3,i) q(3,i)],'color',col(i,:)/2,'linewidth',1.5,'HandleVisibility','off')
            plot(pos(i)+boxw(i)/20, mu(i),'*','color',col(i,:)/2,'linewidth',1,'HandleVisibility','off')
            
    end
end
grid on
box on
end

% Stat functions to avoid using the statistical toolbox
function q = al_quantile(x, p)
sx=sort(x);
indx=(length(x)-1)*p+1;
q=zeros(1,length(p));
for i=1:length(p)
    if floor(indx(i))==indx(i)
        q(i)=sx(indx(i));
    else
        q(i)=(sx(floor(indx(i)))+sx(floor(indx(i))+1))/2;
    end
end
end

function f = al_parzen(x, u, bw)
q=al_quantile(x,[1/4 3/4]);
if nargin<3 || isempty(bw)
    bw=0.9*min(std(x),(q(2)-q(1))/1.35)*length(x)^(-1/5); % Silverman's rule of thumb
end
f=zeros(size(u));
for i=1:length(u)
    f(i)=sum(exp(-0.5*((x-u(i))/bw).^2));
end
f=f/(bw*sqrt(2*pi));
end




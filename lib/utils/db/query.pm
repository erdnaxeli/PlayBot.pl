package utils::db::query;

use feature 'state';
use Moose;
use FindBin;

use lib "$FindBin::Bin/lib/";
use utils::db;


has '_dbh' => (
    is          => 'rw',
    isa         => 'HashRef',
    init_arg    => undef,
    default     => sub { state %h; return \%h; }
);

has '_sth' => (
    is          => 'rw',
    isa         => 'HashRef',
    init_arg    => undef,
    default     => sub { state %h; return \%h; }
);

has '_queries' => (
    is          => 'rw',
    isa         => 'HashRef',
    init_arg    => undef,
    default     => sub { state %h; return \%h; }
);

sub get {
    my ($self, $query) = @_;
    my $chan = $query->chan;
    my $result;

    if (defined $self->_queries->{$chan} and $self->_queries->{$chan} ~~ $query) {
        $result = $self->_get_next($query);
    }
    else {
        $self->_init($query);
        $result = $self->_get_next($query);
    }

    $self->_queries->{$chan} = $query;
    return $result;
}

sub get_rows {
    my ($self, $query) = @_;

    my $dbh = utils::db::get_new_session();
    my ($request, @args) = $self->_prepare_request($query);

    my $sth = $dbh->prepare('select count(*) from ('.$request.') as TGTGTG');
    $sth->execute(@args);

    my $rows = $sth->fetch->[0];
    $sth->finish;
    $dbh->commit;
    $dbh->disconnect;

    return $rows;
}

sub _get_next {
    my ($self, $query) = @_;
    my $chan = $query->chan;
    
    my $result = $self->_sth->{$chan}->fetch();
    return $result if ($result);

    # there is no more data to fetch
    $self->_sth->{$chan} = undef;
    $self->_dbh->{$chan}->commit();
    return undef;
}

sub _init {
    my ($self, $query) = @_;
    my $chan = $query->chan;

    if (defined $self->_sth->{$chan}) {
        $self->_sth->{$chan}->finish();
    }
    elsif (not defined $self->_dbh->{$chan}) {
        $self->_dbh->{$chan} = utils::db::get_new_session();
    }

    my ($request, @args) = $self->_prepare_request($query);
    my $sth = $self->_dbh->{$chan}->prepare($request);
    $sth->execute(@args);

    $self->_sth->{$query->chan} = $sth;
}

sub _prepare_request {
    my ($self, $query) = @_;
    
    my @words_param;
    my $req;
    my @args;

    foreach (@{$query->words}) {
        unshift @words_param, '%'.$_.'%';
    }

    my $words_sql;
    foreach (@{$query->words}) {
        $words_sql .= ' and ' if ($words_sql);
        $words_sql .= "concat(p.sender, ' ', p.title) like ?";
    }

    if ($query->id >= 0) {
        $req = 'select p.id, p.sender, p.title, p.url, p.duration';
        $req .= ' from playbot p where id = ?';

        @args = ($query->id);
    }
    elsif (@{$query->tags}) {
        my @where;

        foreach my $tag (@{$query->tags}) {
            unshift @where, 'p.id in (select pt.id from playbot_tags pt where pt.tag = ?)';
        }

        my $where = join ' and ' => @where;

        if ($query->is_global) {
            $req = 'select p.id, p.sender, p.title, p.url, p.duration';
            $req .= ' from playbot p where '.$where;
            $req .= ' and '.$words_sql if ($words_sql);
            $req .= ' group by p.id order by rand()';

            @args = (@{$query->tags}, @words_param);
        }
        else {
            $req = 'select p.id, p.sender, p.title, p.url, p.duration';
            $req .= ' from playbot p join playbot_chan pc on p.id = pc.content';
            $req .= ' where '.$where;
            $req .= ' and '.$words_sql if ($words_sql);
            $req .= ' and pc.chan = ? group by p.id order by rand()';

            @args = (@{$query->tags}, @words_param, $query->chan);
        }
    }
    else {
        if ($query->is_global) {
            $req = 'select p.id, p.sender, p.title, p.url, p.duration';
            $req .= ' from playbot p';
            $req .= ' where '.$words_sql if ($words_sql);
            $req .= ' group by p.id order by rand()';

            @args = (@words_param);
        }
        else {
            $req = 'select p.id, p.sender, p.title, p.url, p.duration';
            $req .= ' from playbot p join playbot_chan pc on p.id = pc.content';
            $req .= ' where pc.chan = ?';
            $req .= ' and '.$words_sql if ($words_sql);
            $req .= ' group by p.id order by rand()';

            @args = ($query->chan, @words_param);
        }
    }

    return ($req, @args);
}

1;

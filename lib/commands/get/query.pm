package commands::get::query;

use Moose;
use overload '~~' => \&_equals;
use Scalar::Util qw(looks_like_number);

has 'query' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1
);

has 'chan' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1
);

has 'is_global' => (
    is          => 'ro',
    isa         => 'Bool',
    lazy        => 1,
    builder     => '_build_is_global',
    init_arg    => undef
);

has 'tags' => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    lazy        => 1,
    builder     => '_build_tags',
    init_arg    => undef
);

has 'words' => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    lazy        => 1,
    builder     => '_build_words',
    init_arg    => undef
);

has 'id' => (
    is          => 'ro',
    isa         => 'Int',
    lazy        => 1,
    builder     => '_build_id',
    init_arg    => undef
);


sub _build_is_global {
    my $self = shift;

    if ($self->chan !~ /^#/ || $self->query =~ /(^|\s)-a(ll)?($|\s)/) {
        return 1;
    } else {
        return 0;
    }
}

sub _build_tags {
    my $self = shift;

    my $query = $self->query;
    $query =~ s/(^|\s)-a(ll)?($|\s)//;
    
    return [$query =~ /#([a-zA-Z0-9_-]+)/g];
}

sub _build_words {
    my $self = shift;
    
    my $query = $self->query;
    $query =~ s/(^|\s)-a(ll)?($|\s)//;

    return [$query =~ /(?:^| )([^#\s]+)/g];
}

sub _build_id {
    my $self = shift;
    
    if (looks_like_number($self->words->[0])) {
        return $self->words->[0];
    } else {
        return -1;
    }
}

sub _equals {
    my ($self, $query) = @_;

    return 0 unless (ref($self) eq ref($query));

    my @tags1 = sort @{$self->tags};
    my @tags2 = sort @{$query->tags};
    my @words1 = sort @{$self->words};
    my @words2 = sort @{$query->words};

    return ($self->is_global eq $query->is_global
        and @tags1 ~~ @tags2
        and @words1 ~~ @words2
        and $self->id eq $query->id
    );
}

1;

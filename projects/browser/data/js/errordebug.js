if (typeof Duktape !== 'object') {
    print('not Duktape');
} else if (Duktape.version >= 20403) {
    print('Duktape 2.4.3 or higher');
} else if (Duktape.version >= 10500) {
    print('Duktape 1.5.0 or higher (but lower than 2.4.3)');
} else {
    print('Duktape lower than 1.5.0');
}


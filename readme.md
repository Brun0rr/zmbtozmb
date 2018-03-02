# Descrição

O script consiste em ler todas as contas de um determinado domínio em um servidor (origem) e copiar todas as suas informações e conteúdo da mailbox para outro servidor (destino).

# Configuração
## Variáveis para a migração das contas
Devem ser definidas como *TRUE* ou *FALSE*

| Váriavel | Descrição |
|:-------- |:---------:|
| DEFAULT_PASSWORD | Define a senha default para as contas |
| MIG_PASSWORD | Se *TRUE*, migra a senha das contas |
| MIG_WHITELIST | Se *TRUE*, migra as *whitelists* das contas |
| MIG_BLACKLIST | Se *TRUE*, migra as *blacklists* das contas |
| MIG_SIGNATURE_HTML | Se *TRUE*, migra a assinatura das contas |
| MIG_ALIAS | Se *TRUE*, migra os alias das contas |
| MIG_FILTERS | Se *TRUE*, migra os filtros das contas |
| MIG_FORWARD | Se *TRUE*, migra os encaminhamentos das contas |
| MIG_STATUS | Se *TRUE*, migra o status da conta |
| MIG_DISTRIBUTIONLIST | Se *TRUE*, cria as listas de distribuições vinculadas ao dominio a ser migrado |
| MIG_EXECUTE_AFTER | Se *TRUE*, após o script terminar a exportação, será iniciado a importação automaticamente no servidor destino |

## Variáveis para a migração da mailbox

| Váriavel | Descrição | default |
|:-------- |:---------:|:-------:|
| SOURCE_SERVER | Servidor de origem | *none* |
| SOURCE_USER | Admin do zimbra origem | Admin |
| SOURCE_PWD | Senha do zimbra origem | *none* |
| SOURCE_PORT | Porta do zimbra origem | 7071 |
| TARGET_SERVER | Servidor de destino | *none* |
| TARGET_USER | Admin do zimbra destino | Admin |
| TARGET_PWD | Senha do zimbra destino | *none* |
| TARGET_PORT | Porta do zimbra destino | 7071 |

# Modo de usar

 * Trocar as chaves entre o zimbra Origem e Destino, para que a origem possa copiar os arquivos e executar os comandos no servidor destino;
 * Criar a pasta *"/migracao/"* em ambos os servidores;
 * Clone o repositório no servidor **origem** e execute o script conforme abaixo;

```bash
    # Migrando somente as mailboxs
    zmbtozmb.sh zmztozmig <dominio>
```

```bash
    # Migrando as mailbox e os atributos
    zmbtozmb.sh zmmigall <dominio>
```

```bash
    # help
    zmbtozmb.sh help
```


# Desenvolvedores
 * Bruno Ricardo Rodrigues - bruno.rrodrigues@outlook.com
 *  Luciano da Silva - br.lucianosilva@gmail.com
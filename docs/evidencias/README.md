# Diretório de Evidências — Entrega 2

Este diretório armazena as evidências e relatórios exigidos pela Seção 8 e Seção 11 do edital.

---

## 📁 Arquivos a Serem Anexados:

1. **`mfa-gcp.png` (Obrigatório - Controle S8):**
   - Captura de tela comprovando a Verificação em Duas Etapas (MFA) ativada na conta Google Cloud utilizada pelo grupo (sem expor e-mails ou dados sensíveis).

2. **`checkov-report.txt` ou `trivy-report.txt` (Controle S7):**
   - Relatório de saída da análise estática executada na pasta `infra/`.

3. **`gitleaks-report.txt` (Controle S7):**
   - Relatório de saída do escaneamento de segredos no histórico do repositório Git.

4. **`backup-criado.png` (Parte D - B6):**
   - Captura de tela do console do Google Cloud Storage ou saída do comando `gsutil ls gs://.../daily/` demonstrando a existência de ao menos uma cópia de backup gerada antes da apresentação.

5. **`evidencia-destroy.txt` e `console-vazio.png` (Pós-apresentação - Seção 11):**
   - Saída do comando `terraform destroy` e comprovação de que não restaram instâncias, NATs, IPs ou buckets no projeto em até 48 horas após a aula.

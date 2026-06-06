import { PageHeader } from '../components/ui/PageHeader';
import { ContactsEditor } from '../components/ContactsEditor';
import { useI18n } from '../lib/i18n';
import { useAsync } from '../lib/useAsync';
import {
  fetchImportantContacts,
  createImportantContact,
  updateImportantContact,
  deleteImportantContact,
} from '../lib/api';

export function Contacts() {
  const { t } = useI18n();
  const { data, loading, error, reload } = useAsync(fetchImportantContacts, []);

  if (loading) return <div className="p-10 text-center text-ink3">{t('Загрузка…', 'Жүктелуде…')}</div>;
  if (error) return <div className="p-10 text-center text-[#C0492E]">{error}</div>;

  return (
    <div>
      <PageHeader
        title={t('Важные контакты', 'Маңызды контактілер')}
        subtitle={t('Председатель, участковый, экстренные службы', 'Төраға, учаскелік, жедел қызметтер')}
      />
      <ContactsEditor
        mode="important"
        items={data ?? []}
        onCreate={async (input) => { await createImportantContact(input); reload(); }}
        onUpdate={async (id, input) => { await updateImportantContact(id, input); reload(); }}
        onDelete={async (id) => {
          if (!confirm(t('Удалить контакт?', 'Контактіні жою керек пе?'))) return;
          await deleteImportantContact(id); reload();
        }}
      />
    </div>
  );
}
